#!/bin/bash
# Failed validation in Cloud Shell on 4/7/2022

# <FullScript>
# Create a Batch account in Batch service mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-batch-rg-$randomIdentifier"
tag="add-application"
storageAccount="msdocsstorage$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a general-purpose storage account in your resource group.
echo "Creating $storageAccount"
az storage account create --resource-group $resourceGroup --name $storageAccount --location "$location" --sku Standard_LRS

# Create a Batch account.
echo "Creating $batchAccount"
az batch account create --name $batchAccount --storage-account $storageAccount --resource-group $resourceGroup --location "$location"

# Authenticate against the account directly for further CLI interaction.
az batch account login --name $batchAccount --resource-group $resourceGroup --shared-key-auth

# Create a new application.
az batch application create --resource-group $resourceGroup --name $batchAccount --application-name "MyApplication"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y


# An application can reference multiple application executable packages
# of different versions. The executables and any dependencies need
# to be zipped up for the package. Once uploaded, the CLI attempts
# to activate the package so that it's ready for use.
az batch application package create --resource-group $resourceGroup --name $batchAccount --application-name "MyApplication" --package-file my-application-exe.zip --version-name 1.0

# Update the application to assign the newly added application
# package as the default version.
az batch application set --resource-group $resourceGroup --name $batchAccount --application-name "MyApplication" --default-version 1.0
