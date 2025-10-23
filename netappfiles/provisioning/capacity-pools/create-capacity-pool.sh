#!/bin/bash
# Passed validation in Cloud Shell on 07/19/2025

# <FullScript>
# Create capacity pool

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-netappfiles-rg-$randomIdentifier"
tag="create-capacity-pool-netappfiles"
netAppAccount="msdocs-netapp-account-$randomIdentifier"
capacityPool="msdocs-pool-$randomIdentifier"
serviceLevel="Premium"
poolSize="4398046511104" # 4 TiB

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a NetApp account
echo "Creating $netAppAccount"
az netappfiles account create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount

# Create a capacity pool
echo "Creating $capacityPool with $serviceLevel service level"
az netappfiles pool create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --size $poolSize \
    --service-level $serviceLevel

# List capacity pools
echo "Listing capacity pools in $netAppAccount"
az netappfiles pool list \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --query "[].{Name:name,ServiceLevel:serviceLevel,Size:size,ProvisioningState:provisioningState}" \
    --output table

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
