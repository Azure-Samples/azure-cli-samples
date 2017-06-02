#!/bin/bash

# Create a resource group
az group create --name myResourceGroup --location eastus

# Create a general-purpose standard storage account
az storage account create \
    --name mystorageaccount \
    --resource-group myResourceGroup \
    --location eastus \
    --sku Standard_RAGRS \
    --encryption blob

# List the storage account access keys
az storage account keys list \
    --resource-group myResourceGroup \
    --account-name mystorageaccount 

# Renew (rotate) the PRIMARY access key
az storage account keys renew \
    --resource-group myResourceGroup \
    --account-name mystorageaccount \
    --key primary

# Renew (rotate) the SECONDARY access key
az storage account keys renew \
    --resource-group myResourceGroup \
    --account-name mystorageaccount \
    --key secondary
