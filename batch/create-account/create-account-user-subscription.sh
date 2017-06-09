#!/bin/bash

# Authenticate CLI session.
az login

# Allow Azure Batch to access the subscription (one-time operation).
az role assignment create --assignee MicrosoftAzureBatch --role contributor

# Create a resource group.
az group create --name myresourcegroup --location westeurope

# A Batch account that will allocate pools in the user's subscription must be configured
# with a Key Vault located in the same region. Let's create this first.
az keyvault create \
    --resource-group myresourcegroup \
    --name mykevault \
    --location westeurope \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true

# We will add an access-policy to the Key Vault to allow access by the Batch Service.
az keyvault set-policy \
    --resource-group myresourcegroup \
    --name mykevault \
    --spn ddbf3205-c6bd-46ae-8127-60eb93363864 \
    --key-permissions all \
    --secret-permissions all

# Now we can create the Batch account, referencing the Key Vault either by name (if they
# exist in the same resource group) or by its full resource ID.
az batch account create \
    --resource-group myresourcegroup \
    --name mybatchaccount \
    --location westeurope \
    --keyvault mykevault

# We can now authenticate directly against the account for further CLI interaction.
# Note that Batch accounts that allocate pools in the user's subscription must be
# authenticated via an Azure Active Directory token.
az batch account login -g myresourcegroup -n mybatchaccount
