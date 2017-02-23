#!/bin/bash

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a VM
az vm create \
    --resource-group myResourceGroup \
    --name myVM1 \
    --location westus \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword

# Start a CustomScript extension to use a simple bash script to update, download and install WordPress and MySQL 
az vm extension set \
  --name customscript \
  --publisher Microsoft.Powershell \
  --version 2.0 --name DSC \
  --vm-name myVM1 --resource-group myResourceGroup \
  --settings '{"ModulesUrl":["https://raw.githubusercontent.com/Azure/azure-quickstart-templates/blob/master/dsc-extension-iis-server-windows-vm/ContosoWebsite.ps1.zip"], "ConfigurationFunction":"ContosoWebsite.ps1\\ContosoWebsite" }'

  # open port 80 to allow web traffic to host
  az vm open-port \
    --port 80 \
    --priority 300 \
    --resource-group myResourceGroup \
    --name myVM1
    