#!/bin/bash
# Passed validation in Bash in Docker container on Windows 12/01/2021

# <FullScript>
# Manage Transparent Data Encryption in a Managed Instance using your own key from Azure Key Vault

# Run this script after the script in https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/scripts/create-configure-managed-instance-cli creates a managed instance.
# You can use the same variables in both scripts/
# If running this script against a different existing instance, uncomment and add appropriate values to next 3 lines of code
# let "randomIdentifier=$RANDOM*$RANDOM"
# instance="<msdocs-azuresql-instance>" # add instance here
# resourceGroup="<msdocs-azuresql-rg>" # add resource here

# Variable block
location="East US"
vault="msdocssqlvault$randomIdentifier"
key="msdocs-azuresql-key-$randomIdentifier"

# echo assigning identity to service principal in the instance
az sql mi update --name $instance --resource-group $resourceGroup --assign-identity

echo "Creating $vault..."
az keyvault create --name $vault --resource-group $resourceGroup --location "$location"

echo "Getting service principal id and setting policy on $vault..."
instanceId=$(az sql mi show --name $instance --resource-group $resourceGroup --query identity.principalId --output tsv)

echo $instanceId
az keyvault set-policy --name $vault --object-id $instanceId --key-permissions get unwrapKey wrapKey

echo "Creating $key..."
az keyvault key create --name $key --vault-name $vault --size 2048 

# keyPath="C:\yourFolder\yourCert.pfx"
# keyPassword="yourPassword" 
# az keyvault certificate import --file $keyPath --name $key --vault-name $vault --password $keyPassword

echo "Setting security on $instance with $key..."
keyId=$(az keyvault key show --name $key --vault-name $vault -o json --query key.kid | tr -d '"')

az sql mi key create --kid $keyId --managed-instance $instance --resource-group $resourceGroup
az sql mi tde-key set --server-key-type AzureKeyVault --kid $keyId --managed-instance $instance --resource-group $resourceGroup 

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
