#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a general-purpose storage account in your resource group.
az storage account create \
    --resource-group myResourceGroup \
    --name mystorageaccount \
    --location eastus \
    --sku Standard_LRS

# Create a Batch account.
az batch account create \
    --name mybatchaccount \
    --storage-account mystorageaccount \
    --resource-group myResourceGroup \
    --location eastus

# Authenticate against the account directly for further CLI interaction.
az batch account login \
    --name mybatchaccount \
    --resource-group myResourceGroup \
    --shared-key-auth

# Create a new application.
az batch application create \
    --resource-group myResourceGroup \
    --name mybatchaccount \
    --application-name "My Application"

# An application can reference multiple application executable packages
# of different versions. The executables and any dependencies need
# to be zipped up for the package. Once uploaded, the CLI attempts
# to activate the package so that it's ready for use.
az batch application package create \
    --resource-group myResourceGroup \
    --name mybatchaccount \
    --application-name "My Application" \
    --package-file my-application-exe.zip \
    --version-name 1.0

# Update the application to assign the newly added application
# package as the default version.
az batch application set \
    --resource-group myResourceGroup \
    --name mybatchaccount \
    --application-name "My Application" \
    --default-version 1.0