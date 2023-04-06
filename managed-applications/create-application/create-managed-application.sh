#!/bin/bash
# Passed validation in Cloud Shell on 3/7/2022

# <FullScript>
# Define and create a managed application

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
appDefinitionResourceGroup="msdocs-managed-applications-app-definition-rg-$randomIdentifier"
appResourceGroup="msdocs-managed-applications-app-definition-rg-$randomIdentifier"
tag="create-managed-application"
managedApp="StorageApp"

# Create definition for a managed application

# Create a application definition resource group
echo "Creating $appDefinitionResourceGroup in "$location"..."
az group create --name $appDefinitionResourceGroup --location "$location" --tags $tag

# Get Azure Active Directory group to manage the application
groupid=$(az ad group show --group reader --query id --output tsv)

# Get role
roleid=$(az role definition list --name Owner --query [].name --output tsv)

# Create the definition for a managed application
az managedapp definition create --name "$managedApp" --location "$location" --resource-group $appDefinitionResourceGroup --lock-level ReadOnly --display-name "Managed Storage Account" --description "Managed Azure Storage Account" --authorizations "$groupid:$roleid" --package-file-uri "https://raw.githubusercontent.com/Azure/azure-managedapp-samples/master/Managed%20Application%20Sample%20Packages/201-managed-storage-account/managedstorage.zip"

# Create managed application

# Create application resource group
echo "Creating $appResourceGroup in "$location"..."
az group create --name $appResourceGroup --location "$location" --tags $tag

# Get ID of managed application definition
appid=$(az managedapp definition show --name $managedApp --resource-group $appDefinitionResourceGroup --query id --output tsv)

# Get subscription ID
subid=$(az account show --query id --output tsv)

# Construct the ID of the managed resource group
managedGroupId=/subscriptions/$subid/resourceGroups/infrastructureGroup

# Create the managed application
az managedapp create --name storageApp --location "$location" --kind "Servicecatalog" --resource-group $appResourceGroup --managedapp-definition-id $appid --managed-rg-id $managedGroupId --parameters "{\"storageAccountNamePrefix\": {\"value\": \"demostorage\"}, \"storageAccountType\": {\"value\": \"Standard_LRS\"}}"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $appResourceGroup -y
# az group delete --name $appDefinitionResourceGroup -y
