#!/bin/bash

# Create a resource group
az group create --name myResourceGroup --location eastus2

# Create a zone-redundant scale set across zones 1, 2, and 3
# This command also creates a 'Standard' SKU public IP address and loas balancer
# For the Load Balancer Standard SKU, a Network Security Group and rules are also created
az vmss create \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --image UbuntuLTS \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --generate-ssh-keys \
  --zones {1,2,3}

# Apply the Custom Script Extension that installs a basic Nginx webserver
az vmss extension set \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --name CustomScript \
  --resource-group myResourceGroup \
  --vmss-name myScaleSet \
  --settings '{"fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate_nginx.sh"],"commandToExecute":"./automate_nginx.sh"}'

# Output the public IP address to access the site in a web browser
az network public-ip show \
  --resource-group myResourceGroup \
  --name myScaleSetLBPublicIP \
  --query [ipAddress] \
  --output tsv