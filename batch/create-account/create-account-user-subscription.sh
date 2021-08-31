#!/bin/bash

# Allow Azure Batch to access the subscription (one-time operation).
az role assignment create \
    --assignee  ddbf3205-c6bd-46ae-8127-60eb93363864 \
    --role contributor

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create an Azure Key Vault. A Batch account that allocates pools in the user's subscription 
# must be configured with a Key Vault located in the same region. 
az keyvault create \
    --resource-group myResourceGroup \
    --name mykevault \
    --location westeurope \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true

# Add an access policy to the Key Vault to allow access by the Batch Service.
az keyvault set-policy \
    --resource-group myResourceGroup \
    --name mykevault \
    --spn ddbf3205-c6bd-46ae-8127-60eb93363864 \
    --key-permissions all \
    --secret-permissions all

# Create the Batch account, referencing the Key Vault either by name (if they
# exist in the same resource group) or by its full resource ID.
az batch account create \
    --resource-group myResourceGroup \
    --name mybatchaccount \
    --location westeurope \
    --keyvault mykevault

# Authenticate directly against the account for further CLI interaction.
# Batch accounts that allocate pools in the user's subscription must be
# authenticated via an Azure Active Directory token.
az batch account login -g myResourceGroup -n mybatchaccount
