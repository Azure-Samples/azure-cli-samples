#!/bin/bash
# Failed validation in Cloud Shell on 4/7/2022

# <FullScript>
# Create a Batch account in Batch service mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-batch-rg-$randomIdentifier"
storageAccount="msdocsstorage$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"

# Create a resource group.
az group create --name $resourceGroup --location westeurope

# Create a general-purpose storage account in your resource group.
az storage account create \
    --resource-group $resourceGroup \
    --name $storageAccount \
    --location eastus \
    --sku Standard_LRS

# Create a Batch account.
az batch account create \
    --name $batchAccount \
    --storage-account $storageAccount \
    --resource-group $resourceGroup \
    --location eastus

# Authenticate against the account directly for further CLI interaction.
az batch account login \
    --name $batchAccount \
    --resource-group $resourceGroup \
    --shared-key-auth

# Create a new application.
az batch application create \
    --resource-group $resourceGroup \
    --name $batchAccount \
    --application-name "MyApplication" # ?? must exist?

# Error message
(InvalidUri) The requested URI does not represent any resource on the server.
RequestId:f7c76b7e-c324-4a74-a91e-1abfd129880f
Time:2022-04-08T17:47:44.3775560Z
Code: InvalidUri
Message: The requested URI does not represent any resource on the server.
RequestId:f7c76b7e-c324-4a74-a91e-1abfd129880f
Time:2022-04-08T17:47:44.3775560Z
Target: BatchAccount
Exception Details:      (UriPath) /subscriptions/c2ca0ddc-3ddc-45ce-8334-c7b28a9e1c3a/resourceGroups/msdocs-batch-rg-763790012/providers/Microsoft.Batch/batchAccounts/msdocsbatch763790012/applications/My%20Application
        Code: UriPath
        Message: /subscriptions/c2ca0ddc-3ddc-45ce-8334-c7b28a9e1c3a/resourceGroups/msdocs-batch-rg-763790012/providers/Microsoft.Batch/batchAccounts/msdocsbatch763790012/applications/My%20Application     (ParseError) Application names can only contain any combination of alphanumeric characters along with dash (-) and underscore (_). The name must be from 1 through 64 characters long
        Code: ParseError
        Message: Application names can only contain any combination of alphanumeric characters along with dash (-) and underscore (_). The name must be from 1 through 64 characters long


# An application can reference multiple application executable packages
# of different versions. The executables and any dependencies need
# to be zipped up for the package. Once uploaded, the CLI attempts
# to activate the package so that it's ready for use.
az batch application package create \
    --resource-group $resourceGroup \
    --name $batchAccount \
    --application-name "MyApplication" \
    --package-file my-application-exe.zip \
    --version-name 1.0

# Update the application to assign the newly added application
# package as the default version.
az batch application set \
    --resource-group $resourceGroup \
    --name $batchAccount \
    --application-name "MyApplication" \
    --default-version 1.0
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
