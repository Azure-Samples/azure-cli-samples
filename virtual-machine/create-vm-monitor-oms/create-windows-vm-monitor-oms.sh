#!/bin/sh

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

# OMS Id and OMS key.
omsid=<Replace with your OMS Id>
omskey=<Replace with your OMS key>

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual machine. 
az vm create \
    --resource-group myResourceGroup \
    --name myVM \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword 

# Install and configure the OMS agent.
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM --name MicrosoftMonitoringAgent \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'