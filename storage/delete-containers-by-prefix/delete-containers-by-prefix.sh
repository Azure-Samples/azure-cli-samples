#!/bin/bash
# Passed validation in Cloud Shell 03/01/2022

# <FullScript>
# Delete containers by prefix

# Variables for storage
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="delete-containers-by-prefix"
storage="msdocsstorage$randomIdentifier"
container1="msdocs-test1-storage-container-$randomIdentifier"
container2="msdocs-test2-storage-container-test2-$randomIdentifier"
containerProd="msdocs-prod1-storage-$randomIdentifier"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create storage account
echo "Creating $storage..."
az storage account create --name $storage --resource-group $resourceGroup --location "$location" --sku Standard_LRS

# Create some test containers
echo "Creating $container1 $container2 and $containerProd on $storage..."
key=$(az storage account keys list --account-name $storage --resource-group $resourceGroup -o json --query [0].value | tr -d '"')

az storage container create --name $container1 --account-key $key --account-name $storage #--public-access container
az storage container create --name $container2 --account-key $key --account-name $storage #--public-access container
az storage container create --name $containerProd --account-key $key --account-name $storage #--public-access container

# List only the containers with a specific prefix
echo "List container with msdocs-test prefix"
az storage container list --account-key $key --account-name $storage --prefix "msdocs-test" --query "[*].[name]" --output tsv

# Delete 
echo "Deleting msdocs-test containers..."
for container in `az storage container list --account-key $key --account-name $storage --prefix "msdocs-test" --query "[*].[name]" --output tsv`; do
    az storage container delete --account-key $key --account-name $storage --name $container
done

echo "Remaining containers..."
az storage container list --account-key $key --account-name $storage --output table
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
