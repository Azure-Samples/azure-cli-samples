#!/bin/bash
# Passed validation in Cloud Shell 03/01/2022

# <FullScript>
# Calculate container size

# Variables for storage
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="calculate-container-size"
storage="msdocsstorage$randomIdentifier"
container="msdocs-storage-container-$randomIdentifier"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create storage account
echo "Creating $storage..."
az storage account create --name $storage --resource-group $resourceGroup --location "$location" --sku Standard_LRS

# Create a container
echo "Creating $container on $storage..."
key=$(az storage account keys list --account-name $storage --resource-group $resourceGroup -o json --query [0].value | tr -d '"')

az storage container create --name $container --account-key $key --account-name $storage #--public-access container

# Create sample files to upload as blobs
for i in `seq 1 3`; do
    echo $randomIdentifier > container_size_sample_file_$i.txt
done

# Upload sample files to container
az storage blob upload-batch \
    --pattern "container_size_sample_file_*.txt" \
    --source . \
    --destination $container \
    --account-key $key \
    --account-name $storage

# Calculate total size of container. Use the --query parameter to display only
# blob contentLength and output it in TSV format so only the values are
# returned. Then pipe the results to the paste and bc utilities to total the
# size of the blobs in the container. The bc utility is not supported in Cloud Shell.
bytes=`az storage blob list \
    --container-name $container \
    --account-key $key \
    --account-name $storage \
    --query "[*].[properties.contentLength]" \
    --output tsv | paste -s -d+ | bc`

# Display total bytes
echo "Total bytes in container: $bytes"

# Delete the sample files created by this script
rm container_size_sample_file_*.txt
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
