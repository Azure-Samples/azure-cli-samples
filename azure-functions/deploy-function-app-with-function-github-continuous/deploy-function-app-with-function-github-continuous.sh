#!/bin/bash
# TODO: Validate in Cloud Shell before merging

# Function app, storage account, and user identity names must be unique.
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="deploy-function-app-with-function-github"
storage="msdocsaccount$randomIdentifier"
userIdentity="msdocs-managed-identity-$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
skuStorage="Standard_LRS"
functionsVersion="4"
languageWorker="node"
languageVersion="20"
# Public GitHub repository containing an Azure Functions code project.
gitrepo=https://github.com/Azure-Samples/functions-quickstart-javascript

# Install the Application Insights extension
az extension add --name application-insights

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an Azure storage account in the resource group with key access disabled.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup \
    --sku $skuStorage --allow-blob-public-access false --allow-shared-key-access false

# Create a user-assigned managed identity
echo "Creating $userIdentity"
output=$(az identity create --name $userIdentity --resource-group $resourceGroup --location $location \
    --query "{userId:id, principalId: principalId, clientId: clientId}" -o json)

# Use jq to parse the output and assign the properties to variables
userId=$(echo $output | jq -r '.userId')
principalId=$(echo $output | jq -r '.principalId')
clientId=$(echo $output | jq -r '.clientId')

# Get the storage ID and create a role assignment (Storage Blob Data Owner) for the identity
storageId=$(az storage account show --resource-group $resourceGroup --name $storage --query 'id' -o tsv)
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Owner" --scope $storageId

# Create the function app in a Flex Consumption plan with source files deployed from GitHub
echo "Creating $functionApp"
az functionapp create --resource-group $resourceGroup --name $functionApp --flexconsumption-location $location \
    --runtime $languageWorker --runtime-version $languageVersion --storage-account $storage \
    --deployment-storage-auth-type UserAssignedIdentity --deployment-storage-auth-value $userIdentity \
    --deployment-source-url $gitrepo --deployment-source-branch main

# Create a role assignment (Monitoring Metrics Publisher) in Application Insights for the user identity
appInsights=$(az monitor app-insights component show --resource-group $resourceGroup \
    --app $functionApp --query "id" --output tsv)
az role assignment create --role "Monitoring Metrics Publisher" --assignee $principalId --scope $appInsights

# Update app settings to use managed identities for host storage connections
clientId=$(az identity show --name $userIdentity --resource-group $resourceGroup \
    --query 'clientId' -o tsv)
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup \
    --settings AzureWebJobsStorage__accountName=$storage AzureWebJobsStorage__credential=managedidentity \
    AzureWebJobsStorage__clientId=$clientId \
    APPLICATIONINSIGHTS_AUTHENTICATION_STRING="ClientId=$clientId;Authorization=AAD"
az functionapp config appsettings delete --name $functionApp \
    --resource-group $resourceGroup --setting-names AzureWebJobsStorage

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
