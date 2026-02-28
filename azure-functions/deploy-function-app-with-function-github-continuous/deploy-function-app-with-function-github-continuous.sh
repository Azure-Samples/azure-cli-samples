#!/bin/bash
# TODO: Validate in Cloud Shell before merging

# Function app and storage account names must be unique.
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="deploy-function-app-with-function-github"
storage="msdocsaccount$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
skuStorage="Standard_LRS"
functionsVersion="4"
runtime="node"
runtimeVersion="20"
# Public GitHub repository containing an Azure Functions code project.
gitrepo=https://github.com/Azure-Samples/functions-quickstart-javascript

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an Azure storage account in the resource group.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# Create a serverless function app in the resource group.
echo "Creating $functionApp"
az functionapp create --name $functionApp --storage-account $storage \
    --consumption-plan-location "$location" --resource-group $resourceGroup \
    --runtime $runtime --runtime-version $runtimeVersion \
    --functions-version $functionsVersion \
    --deployment-source-url $gitrepo --deployment-source-branch main

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
