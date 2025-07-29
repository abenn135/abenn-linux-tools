#!/bin/bash
rproot () {
    # This function changes the current directory to the root of the AKS RP repository.
    # It uses 'sed' to extract the path up to 'aks/rp' and then changes to that child directory.
    cd "$( pwd | sed -E 's/(.*aks\/rp).*/\1/' )"
}
