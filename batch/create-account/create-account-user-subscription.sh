#!/bin/bash
# Failed validation in Cloud Shell on 4/7/2022

# <FullScript>
# Create a Batch account in user subscription mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
subscriptionId="$(az account show --query id -o tsv)"
role="contributor"
location="East US"
servicePrincipal="msdocssp$randomIdentifier"
resourceGroup="msdocs-batch-rg-$randomIdentifier"
tag="create-account"
keyVault="msdocskeyvault$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"
storageAccount="msdocsstorage$randomIdentifier"
skuStorage="Standard_LRS"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles

az ad sp create-for-rbac --name $servicePrincipal --role contributor  --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
apId=$(az ad sp list --display-name $servicePrincipal --query "[].appId" --output tsv)

# Allow Azure Batch to access the subscription (one-time operation).
#az role assignment create \
#    --assignee $apId \
#    --role $role

# Create an Azure Key Vault. A Batch account that allocates pools in the user's subscription 
# must be configured with a Key Vault located in the same region.
echo "Creating $keyVault" 
az keyvault create \
    --resource-group $resourceGroup \
    --name $keyVault \
    --location "$location" \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true

# Add an access policy to the Key Vault to allow access by the Batch Service.
az keyvault set-policy \
    --resource-group $resourceGroup \
    --name $keyVault \
    --spn $apId \
    --key-permissions all \
    --secret-permissions all

# Create the Batch account, referencing the Key Vault either by name (if they
# exist in the same resource group) or by its full resource ID.
az batch account create \
    --resource-group $resourceGroup \
    --name $batchAccount \
    --location "$location" \
    --keyvault $keyVault 

# error message
(InsufficientPermissions) The Batch service does not have the required permissions to access the specified Subscription.
RequestId:0c225edb-9138-431c-b2fd-bc8495b0a5a4
Time:2022-04-07T16:11:55.6120867Z
Code: InsufficientPermissions
Message: The Batch service does not have the required permissions to access the specified Subscription.
RequestId:0c225edb-9138-431c-b2fd-bc8495b0a5a4
Time:2022-04-07T16:11:55.6120867Z
Target: BatchAccount



# Authenticate directly against the account for further CLI interaction.
# Batch accounts that allocate pools in the user's subscription must be
# authenticated via an Azure Active Directory token.
az batch account login -g $resourceGroup -n $batchAccount
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
