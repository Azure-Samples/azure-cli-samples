#!/bin/bash
# TODO: Validate in Cloud Shell before merging

# Function app, storage account, and user identity names must be unique.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="swedencentral"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="connect-azure-openai-resources"
storage="msdocsaccount$randomIdentifier"
userIdentity="msdocs-managed-identity-$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
openaiName="msdocs-openai-$randomIdentifier"
modelName="gpt-4o"
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

# Get the storage ID and create a role assignment (Storage Blob Data Owner) for the user
storageId=$(az storage account show --resource-group $resourceGroup --name $storage --query 'id' -o tsv)
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Owner" --scope $storageId

# Create the function app in a Flex Consumption plan that uses the user-assigned managed identity
# to access the deployment share.
az functionapp create --resource-group $resourceGroup --name $functionApp --flexconsumption-location $location  \
    --runtime $languageWorker --runtime-version $languageVersion --storage-account $storage \
    --deployment-storage-auth-type UserAssignedIdentity --deployment-storage-auth-value $userIdentity 

# Create a role assigment (Monitoring Metrics Publisher) in Application Insights for the user identity
appInsights=$(az monitor app-insights component show --resource-group $resourceGroup \
    --app $functionApp --query "id" --output tsv)
az role assignment create --role "Monitoring Metrics Publisher" --assignee $principalId --scope $appInsights

# Update app settings to use managed identities for all connections
clientId=$(az identity show --name $userIdentity --resource-group $resourceGroup \
    --query 'clientId' -o tsv)
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup \
    --settings AzureWebJobsStorage__accountName=$storage AzureWebJobsStorage__credential=managedidentity \
    AzureWebJobsStorage__clientId=$clientId \
    APPLICATIONINSIGHTS_AUTHENTICATION_STRING="ClientId=$clientId;Authorization=AAD"
az functionapp config appsettings delete --name $functionApp \
    --resource-group $resourceGroup --setting-names AzureWebJobsStorage

# Create an Azure OpenAI resource
echo "Creating Azure OpenAI resource"
openaiId=$(az cognitiveservices account create --name $openaiName \
    --resource-group $resourceGroup --kind OpenAI --sku S0 --location $location --yes \
    --query 'id' -o tsv)

# Create role assignments ("Cognitive Services OpenAI User" & "Azure AI User") for the identity
echo "Adding UAMI to the 'Cognitive Services OpenAI User' role."
principalId=$(az identity show --name $userIdentity --resource-group $resourceGroup \
    --query 'principalId' -o tsv)
az role assignment create --assignee $principalId \
    --role "Cognitive Services OpenAI User" --scope $openaiId
az role assignment create --assignee $principalId \
    --role "Azure AI User" --scope $openaiId

# Create the same role assignments for your Azure account so you can connect during local development.
echo "Adding current Azure account to the 'Cognitive Services OpenAI User' role."
accountId=$(az ad signed-in-user show --query id -o tsv)
az role assignment create --assignee $accountId \
    --role "Cognitive Services OpenAI User" --scope $openaiId
az role assignment create --assignee $accountId \
    --role "Azure AI User" --scope $openaiId

# Get the user-assigned managed identity details
user=$(az identity show --name $userIdentity --resource-group $resourceGroup \
    --query "{userId:id, clientId: clientId}" -o json)

# Add the required app settings to the function app
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup \
    --settings AzureOpenAI__Endpoint="https://$openaiName.openai.azure.com/" \
    AzureOpenAI__credential=managedidentity \
    AzureOpenAI__managedIdentityResourceId=$(echo $user | jq -r '.userId') \
    AzureOpenAI__clientId=$(echo $user | jq -r '.clientId') \
    CHAT_MODEL_DEPLOYMENT_NAME=$modelName

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
