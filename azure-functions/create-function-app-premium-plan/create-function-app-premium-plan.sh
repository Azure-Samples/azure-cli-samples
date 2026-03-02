#!/bin/bash
# Passed validation in Cloud Shell on 2/28/2026

# For the recommended serverless plan, see create-function-app-flex-consumption.
# Function app and storage account names must be unique.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="create-function-app-premium-plan"
storage="msdocsaccount$randomIdentifier"
premiumPlan="msdocs-premium-plan-$randomIdentifier"
functionApp="msdocs-function-$randomIdentifier"
skuStorage="Standard_LRS"
skuPlan="EP1"
functionsVersion="4"
runtime="node"
runtimeVersion="20"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an Azure storage account in the resource group.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# Create a Premium plan
echo "Creating $premiumPlan"
az functionapp plan create --name $premiumPlan --resource-group $resourceGroup --location "$location" --sku $skuPlan

# Create a Function App
echo "Creating $functionApp"
az functionapp create --name $functionApp --storage-account $storage \
    --plan $premiumPlan --resource-group $resourceGroup --os-type Linux \
    --runtime $runtime --runtime-version $runtimeVersion \
    --functions-version $functionsVersion

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
