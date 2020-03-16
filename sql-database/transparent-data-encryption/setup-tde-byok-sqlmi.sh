#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$instance = "<instanceId>" # add instance here
$location = "East US"

$randomIdentifier = $(Get-Random)

$vault = "vault-$randomIdentifier"
$key = "key-$randomIdentifier"

echo "Using resource group $($resourceGroup)..."

echo "Creating $($resourceGroup)..."
az group create --name $resourceGroup --location $location

echo "Creating $($vault)..."
az keyvault create --name $vault --resource-group $resourcegroup --enable-soft-delete true --location $location

echo "Setting policy on $($vault)..."
$instanceId = az sql mi show --name $instance --resource-group $resourceGroup -o json --query identity.principalId

az keyvault set-policy --name $vault --key-permissions get, unwrapKey, wrapKey --object-id $instanceId

echo "Creating $($key)..."
az keyvault key create --name $key --vault-name $vault --size 2048 

#$keyPath = "C:\yourFolder\yourCert.pfx"
#$keyPassword = "yourPassword" 
#az keyvault certificate import --file $keyPath --name $key --vault-name $vault --password $keyPassword

echo "Setting security on $($instance) with $($key)..."
$keyId = az keyvault key show --name $key --vault-name $vault -o json --query key.kid

az sql mi key create --kid $keyId --managed-instance $instance --resource-group $resourcegroup
az sql mi tde-key set --server-key-type AzureKeyVault --kid $keyId --managed-instance $instance --resource-group $resourcegroup 