#!/bin/bash
# TODO: Validate in Cloud Shell before merging

# For the recommended serverless plan, see create-function-app-flex-consumption.
# Function app and storage account names must be unique.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="create-function-app-app-service-plan"
storage="msdocsaccount$randomIdentifier"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
skuStorage="Standard_LRS"
skuPlan="B1"
functionsVersion="4"
runtime="dotnet-isolated"
runtimeVersion="8.0"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an Azure storage account in the resource group.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# Create an App Service plan
echo "Creating $appServicePlan"
az functionapp plan create --name $appServicePlan --resource-group $resourceGroup \
    --location "$location" --sku $skuPlan

# Create a Function App
echo "Creating $functionApp"
az functionapp create --name $functionApp --storage-account $storage \
    --plan $appServicePlan --resource-group $resourceGroup \
    --runtime $runtime --runtime-version $runtimeVersion \
    --functions-version $functionsVersion

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
