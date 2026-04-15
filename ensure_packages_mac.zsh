#!/bin/zsh

setopt errexit

if [ "$(uname -s)"  != "Darwin" ]; then
  echo "Not running on Mac OS! No promises."
fi

which brew
if [ ! $? ]; then
  echo "no brew detected. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew install gawk
brew tap hashicorp/tap
brew install hashicorp/tap/vault
brew install sk
