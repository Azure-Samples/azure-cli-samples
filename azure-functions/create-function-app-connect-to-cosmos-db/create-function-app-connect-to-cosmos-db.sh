#!/bin/bash

# TODO: Validate in Cloud Shell before merging

# Function app, storage account, Cosmos DB, and user identity names must be unique.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="create-function-app-connect-to-cosmos-db"
storage="msdocsaccount$randomIdentifier"
userIdentity="msdocs-managed-identity-$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
cosmosDbAccount="msdocs-cosmosdb-$randomIdentifier"
skuStorage="Standard_LRS"
functionsVersion="4"
languageWorker="python"
languageVersion="3.11"

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

# Create the function app in a Flex Consumption plan
echo "Creating $functionApp"
az functionapp create --resource-group $resourceGroup --name $functionApp --flexconsumption-location $location \
    --runtime $languageWorker --runtime-version $languageVersion --storage-account $storage \
    --deployment-storage-auth-type UserAssignedIdentity --deployment-storage-auth-value $userIdentity

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

# Create an Azure Cosmos DB account
echo "Creating $cosmosDbAccount"
az cosmosdb create --name $cosmosDbAccount --resource-group $resourceGroup --location $location

# Assign the Cosmos DB Built-in Data Contributor role to the managed identity
cosmosDbId=$(az cosmosdb show --name $cosmosDbAccount --resource-group $resourceGroup --query 'id' -o tsv)
az cosmosdb sql role assignment create --account-name $cosmosDbAccount --resource-group $resourceGroup \
    --role-definition-name "Cosmos DB Built-in Data Contributor" --scope "/" \
    --principal-id $principalId

# Get the Cosmos DB endpoint and configure the function app to connect using managed identity
endpoint=$(az cosmosdb show --name $cosmosDbAccount --resource-group $resourceGroup --query documentEndpoint --output tsv)
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup \
    --settings CosmosDB__accountEndpoint=$endpoint CosmosDB__credential=managedidentity \
    CosmosDB__clientId=$clientId

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
