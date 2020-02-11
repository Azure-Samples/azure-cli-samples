#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$vault = "vault-$randomIdentifier"
$instance = "instance-$randomIdentifier"
$key = "key-$randomIdentifier"

$keyPath = "c:\some_path\mytdekey.pfx"
$keyPassword = ConvertTo-SecureString -String "<PFX private key password>" -AsPlainText -Force 

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup)..."
az group create --name $resourceGroup --location $location

echo "Creating $($vault)..."
az keyvault create --name $vault --resource-group $resourcegroup --enable-soft-delete true --location $location

echo "Setting policy on $($vault)..."
$instanceId = az sql mi show --name $instance --resource-group $resourceGroup -o json --query [0].identity.principalid

az keyvault set-policy --name $vault --key-permissions get, unwrapKey, wrapKey --object-id $instanceId #-BypassObjectIdValidation
#az sql mi update [--add][--name $instance[--resource-group $resourcegroup
#az keyvault network-rule add --name $vault #Update-AzKeyVaultNetworkRuleSet -VaultName  -Bypass AzureServices # allow access from trusted Azure services: 
#az keyvault network-rule add --name $vault #Update-AzKeyVaultNetworkRuleSet -VaultName  -DefaultAction Deny # turn the network rules ON by setting the default action to Deny:

echo "Creating $($key)..."
az keyvault certificate import --file $keyPath --name $key --vault-name $vault --password $keyPassword
#az keyvault key create --name $key --vault-name $vault --size 2048 # use to generate a new key

echo "Setting $($instance) security using $($key)..."
$keyId = az keyvault key show --name $key --vault-name $vault -o json --query [0].value

az sql mi key create --kid $keyId --managed-instance $instance --resource-group $resourcegroup
az sql mi tde-key set --server-key-type AzureKeyVault --kid $keyId --managed-instance $instance --resource-group $resourcegroup 