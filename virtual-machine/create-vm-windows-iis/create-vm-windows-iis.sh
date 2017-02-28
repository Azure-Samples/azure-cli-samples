#!/bin/bash

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual machine. 
az vm create \
    --resource-group myResourceGroup \
    --name myVM \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword

# Open port 80 to allow web traffic to host.
az vm open-port --port 80 --resource-group myResourceGroup --name myVM 

# Use CustomScript extension to install Apache.
az vm extension set \
  --publisher Microsoft.Compute \
  --version 1.8 \
  --name CustomScriptExtension \
  --vm-name myVM \
  --resource-group myResourceGroup \
  --settings '{"commandToExecute":"powershell.exe Install-WindowsFeature -Name Web-Server"}'