#!/bin/bash

setup_aks_jumpbox() {
    # Prompt for cluster and nodepool information
    read -p "Enter AKS cluster name: " CLUSTER_NAME
    read -p "Enter resource group name: " RESOURCE_GROUP
    read -p "Enter nodepool name: " NODEPOOL_NAME
    
    # Validate inputs
    if [[ -z "$CLUSTER_NAME" || -z "$RESOURCE_GROUP" || -z "$NODEPOOL_NAME" ]]; then
        echo "Error: All fields are required"
        return 1
    fi
    
    echo "Setting up jumpbox for AKS cluster: $CLUSTER_NAME, nodepool: $NODEPOOL_NAME"
    
    # Get nodepool subnet ID
    echo "Fetching nodepool subnet information..."
    SUBNET_ID=$(az aks nodepool show --cluster-name "$CLUSTER_NAME" --name "$NODEPOOL_NAME" --resource-group "$RESOURCE_GROUP" --query "vnetSubnetId" -o tsv)
    
    if [[ -z "$SUBNET_ID" ]]; then
        echo "Error: Could not retrieve subnet ID for nodepool $NODEPOOL_NAME"
        return 1
    fi
    
    echo "Found subnet: $SUBNET_ID"
    
    # Get node resource group (where VMSS is located)
    echo "Getting node resource group..."
    NODE_RESOURCE_GROUP=$(az aks show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --query "nodeResourceGroup" -o tsv)
    
    if [[ -z "$NODE_RESOURCE_GROUP" ]]; then
        echo "Error: Could not retrieve node resource group for cluster $CLUSTER_NAME"
        return 1
    fi
    
    echo "Found node resource group: $NODE_RESOURCE_GROUP"
    
    # Generate SSH key pair
    SSH_KEY_NAME="aks-jumpbox-key-$(date +%s)"
    SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"
    
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_KEY_PATH" -N "" -q
    
    # Get VMSS name for the nodepool (from the node resource group)
    echo "Finding VMSS for nodepool..."
    VMSS_NAME=$(az vmss list --resource-group "$NODE_RESOURCE_GROUP" --query "[?contains(name, '$NODEPOOL_NAME')].name" -o tsv | head -1)
    
    if [[ -z "$VMSS_NAME" ]]; then
        echo "Error: Could not find VMSS for nodepool $NODEPOOL_NAME"
        return 1
    fi
    
    echo "Found VMSS: $VMSS_NAME"
    
    # Create jumpbox VM
    JUMPBOX_NAME="jumpbox-${CLUSTER_NAME}-${NODEPOOL_NAME}"
    echo "Creating jumpbox VM: $JUMPBOX_NAME"
    
    az vm create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$JUMPBOX_NAME" \
        --image "Ubuntu2204" \
        --subnet "$SUBNET_ID" \
        --ssh-key-values "${SSH_KEY_PATH}.pub" \
        --admin-username azureuser \
        --size Standard_B1s \
        --nsg "" \
        --output table
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create jumpbox VM"
        return 1
    fi
    
    # Get jumpbox public IP
    echo "Getting jumpbox public IP..."
    JUMPBOX_PUBLIC_IP=$(az vm show -d --resource-group "$RESOURCE_GROUP" --name "$JUMPBOX_NAME" --query "publicIps" -o tsv)
    
    if [[ -z "$JUMPBOX_PUBLIC_IP" ]]; then
        echo "Error: Could not retrieve public IP for jumpbox $JUMPBOX_NAME"
        return 1
    fi
    
    # Copy SSH private key to jumpbox so it can connect to VMSS nodes
    echo "Copying SSH private key to jumpbox..."
    
    # Wait for the VM to be fully ready by polling its provisioning state
    echo "Waiting for jumpbox to be ready..."
    while true; do
        PROVISIONING_STATE=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$JUMPBOX_NAME" --query "provisioningState" -o tsv)
        if [[ "$PROVISIONING_STATE" == "Succeeded" ]]; then
            echo "Jumpbox is ready (provisioningState: $PROVISIONING_STATE)"
            break
        else
            echo "Jumpbox provisioning state: $PROVISIONING_STATE - waiting..."
            sleep 3
        fi
    done
    
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$SSH_KEY_PATH" azureuser@$JUMPBOX_PUBLIC_IP:/home/azureuser/.ssh/nodepool_key
    
    if [[ $? -ne 0 ]]; then
        echo "Warning: Failed to copy SSH key to jumpbox. You may need to copy it manually."
    else
        echo "SSH key successfully copied to jumpbox at /home/azureuser/.ssh/nodepool_key"
    fi
    
    # Reset SSH key on VMSS
    echo "Resetting SSH key on VMSS: $VMSS_NAME"
    az vmss extension set \
        --resource-group "$NODE_RESOURCE_GROUP" \
        --vmss-name "$VMSS_NAME" \
        --name VMAccessForLinux \
        --publisher Microsoft.OSTCExtensions \
        --version 1.4 \
        --settings "{\"username\":\"azureuser\",\"ssh_key\":\"$(cat ${SSH_KEY_PATH}.pub)\"}"
    
    # Update VMSS instances
    echo "Updating VMSS instances..."
    az vmss update-instances \
        --resource-group "$NODE_RESOURCE_GROUP" \
        --name "$VMSS_NAME" \
        --instance-ids "*"
    
    # Get jumpbox private IP
    JUMPBOX_PRIVATE_IP=$(az vm show -d --resource-group "$RESOURCE_GROUP" --name "$JUMPBOX_NAME" --query "privateIps" -o tsv)
    
    echo ""
    echo "Setup completed successfully!"
    echo "=========================="
    echo "Jumpbox VM: $JUMPBOX_NAME"
    echo "Public IP: $JUMPBOX_PUBLIC_IP"
    echo "Private IP: $JUMPBOX_PRIVATE_IP"
    echo "SSH Key: $SSH_KEY_PATH"
    echo "SSH Command: ssh -i $SSH_KEY_PATH azureuser@$JUMPBOX_PUBLIC_IP"
    echo ""
    echo "On the jumpbox, use this key to connect to VMSS nodes:"
    echo "ssh -i /home/azureuser/.ssh/nodepool_key azureuser@<node_ip>"
    echo ""
}

# Call the function
setup_aks_jumpbox