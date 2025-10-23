#!/bin/bash
# Passed validation in Cloud Shell on 07/19/2025

# <FullScript>
# Create Azure NetApp Files account

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-netappfiles-rg-$randomIdentifier"
tag="create-netapp-account-netappfiles"
netAppAccount="msdocs-netapp-account-$randomIdentifier"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a NetApp account
echo "Creating $netAppAccount"
az netappfiles account create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount

# Verify NetApp account creation
echo "Verifying $netAppAccount"
az netappfiles account show \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --query "{Name:name,Location:location,ProvisioningState:provisioningState}" \
    --output table

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
