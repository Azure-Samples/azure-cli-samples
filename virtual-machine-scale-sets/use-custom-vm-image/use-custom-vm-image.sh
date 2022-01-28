# to be deleted - replaced by create-use-custom-image.sh
#!/bin/bash

# Create a resource group
az group create --name myResourceGroup --location eastus

# Create a scale set

# Custom VM image must already exist in your subscription
# See https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/tutorial-use-custom-image-cli

# Network resources such as an Azure load balancer are automatically created
az vmss create \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --image myImage \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --generate-ssh-keys
