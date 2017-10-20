#!/bin/bash

# Create resource group
az group create --name applicationGroup --location westcentralus 

# Get ID of managed application definition
appid=$(az managedapp definition show --name ManagedStorage --resource-group appDefinitionGroup --query id --output tsv)

# Get subscription ID
subid=$(az account show --query id --output tsv)

# Construct the ID of the managed resource group
managedGroupId=/subscriptions/$subid/resourceGroups/infrastructureGroup

# Create the managed application
az managedapp create \
  --name storageApp \
  --location "westcentralus" \
  --kind "Servicecatalog" \
  --resource-group applicationGroup \
  --managedapp-definition-id $appid \
  --managed-rg-id $managedGroupId \
  --parameters "{\"storageAccountNamePrefix\": {\"value\": \"demostorage\"}, \"storageAccountType\": {\"value\": \"Standard_LRS\"}}"
