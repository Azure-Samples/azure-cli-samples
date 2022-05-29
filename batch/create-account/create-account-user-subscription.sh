# test 5-29
#!/bin/bash
# Passed validation in Cloud Shell on 5/24/2022

# <FullScript>
# Create a Batch account in user subscription mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
[[ "$RESOURCE_GROUP" == '' ]] && resourceGroup="msdocs-batch-rg-$randomIdentifier" || resourceGroup="${RESOURCE_GROUP}"
tag="create-account-user-subscription"
keyVault="msdocskeyvault$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"

# Allow Azure Batch to access the subscription (one-time operation).
az role assignment create --assignee ddbf3205-c6bd-46ae-8127-60eb93363864 --role contributor

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an Azure Key Vault. A Batch account that allocates pools in the user's subscription 
# must be configured with a Key Vault located in the same region.
echo "Creating $keyVault" 
az keyvault create --resource-group $resourceGroup --name $keyVault --location "$location" --enabled-for-deployment true --enabled-for-disk-encryption true --enabled-for-template-deployment true

# Add an access policy to the Key Vault to allow access by the Batch Service.
az keyvault set-policy --resource-group $resourceGroup --name $keyVault --spn ddbf3205-c6bd-46ae-8127-60eb93363864 --key-permissions all --secret-permissions all

# Create the Batch account, referencing the Key Vault either by name (if they
# exist in the same resource group) or by its full resource ID.
echo "Creating $batchAccount"
az batch account create --resource-group $resourceGroup --name $batchAccount --location "$location" --keyvault $keyVault 

# Authenticate directly against the account for further CLI interaction.
# Batch accounts that allocate pools in the user's subscription must be
# authenticated via an Azure Active Directory token.
az batch account login -g $resourceGroup -n $batchAccount
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
