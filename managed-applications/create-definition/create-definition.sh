#!/bin/bash

# Create resource group
az group create --name appDefinitionGroup --location westcentralus

# Get Azure Active Directory group to manage the application
groupid=$(az ad group show --group appManagers --query objectId --output tsv)

# Get role
roleid=$(az role definition list --name Owner --query [].name --output tsv)

# Create the definition for a managed application
az managedapp definition create \
  --name "ManagedStorage" \
  --location "westcentralus" \
  --resource-group appDefinitionGroup \
  --lock-level ReadOnly \
  --display-name "Managed Storage Account" \
  --description "Managed Azure Storage Account" \
  --authorizations "$groupid:$roleid" \
  --package-file-uri "https://raw.githubusercontent.com/Azure/azure-managedapp-samples/master/Managed%20Application%20Sample%20Packages/201-managed-storage-account/managedstorage.zip"
