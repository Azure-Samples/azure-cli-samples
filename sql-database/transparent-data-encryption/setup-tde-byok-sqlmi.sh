#!/bin/bash
# Passed validation in Cloud Shell 11/28/2021

let randomIdentifier=$RANDOM*$RANDOM

#Run this script after create-manage-instance.sh script creates a managed instance
#instance="<instanceId>" # add instance here
#resource="<resourceId>" # add resource here

location="East US"
vault="vault-$randomIdentifier"
key="key-$randomIdentifier"

#echo assigning identity to service principal in the instance
az sql mi update --name $instance --resource-group $resource --assign-identity

echo "Creating $vault..."
#az keyvault create --name $vault --resource-group $resource --enable-soft-delete true --location "$location"

az keyvault create --name $vault --resource-group $resource --location "$location"

#echo "Getting service principal id and setting policy on $vault..."

instanceId=$(az sql mi show --name $instance --resource-group $resource --query identity.principalId --output tsv)
echo $instanceId
az keyvault set-policy --name $vault --object-id $instanceId --key-permissions get unwrapKey wrapKey

echo "Creating $key..."
az keyvault key create --name $key --vault-name $vault --size 2048 

#keyPath="C:\yourFolder\yourCert.pfx"
#keyPassword="yourPassword" 
#az keyvault certificate import --file $keyPath --name $key --vault-name $vault --password $keyPassword

echo "Setting security on $instance with $key..."
keyId=$(az keyvault key show --name $key --vault-name $vault -o json --query key.kid | tr -d '"')

az sql mi key create --kid $keyId --managed-instance $instance --resource-group $resource
az sql mi tde-key set --server-key-type AzureKeyVault --kid $keyId --managed-instance $instance --resource-group $resource 

# echo "Deleting all resources"
# az group delete --name $resource -y
