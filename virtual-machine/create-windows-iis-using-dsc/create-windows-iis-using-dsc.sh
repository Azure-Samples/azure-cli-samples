#!/bin/bash

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a VM
az vm create \
    --resource-group myResourceGroup \
    --name myVM \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword

# Start a CustomScript extension to use a simple bash script to update, download and install WordPress and MySQL 
az vm extension set \
   --name DSC \
   --publisher Microsoft.Powershell \
   --version 2.19 \
   --vm-name myVM \
   --resource-group myResourceGroup \
   --settings '{"ModulesURL":"https://github.com/Azure/azure-quickstart-templates/raw/master/dsc-extension-iis-server-windows-vm/ContosoWebsite.ps1.zip", "configurationFunction": "ContosoWebsite.ps1\\ContosoWebsite", "Properties": {"MachineName": "myVM"} }'

  # open port 80 to allow web traffic to host
  az vm open-port \
    --port 80 \
    --resource-group myResourceGroup \
    --name myVM
    