---
Info: This version of create-function-app-flex-plan-identities is maintained for  hosting code snippets in the Functions Flex CLI quickstarts.
Date: 05/15/2025
Version: 1.0
AI-assisted: true
---

# Snippet source for create-function-app-flex-plan-identities

```bash
# Install the Application Insights extension
az extension add --name application-insights

# Create a resource group
az group create --name "AzureFunctionsQuickstart-rg" --location "<REGION>" --tags $tag

# Create an Azure storage account in the resource group with key access disabled.
az storage account create --name <STORAGE_NAME> --location "<REGION>" --resource-group "AzureFunctionsQuickstart-rg" \
    --sku "Standard_LRS" --allow-blob-public-access false --allow-shared-key-access false

# Create a user-assigned managed identity
output=$(az identity create --name <USER_NAME> --resource-group "AzureFunctionsQuickstart-rg" --location <REGION> \
    --query "{userId:id, principalId: principalId, clientId: clientId}" -o json)

# Use jq to parse the output and assign the properties to variables
userId=$(echo $output | jq -r '.userId')
principalId=$(echo $output | jq -r '.principalId')
clientId=$(echo $output | jq -r '.clientId')

# Get the storage ID and create a role assignment (Storage Blob Data Owner) for the user
storageId=$(az storage account show --resource-group "AzureFunctionsQuickstart-rg" --name <STORAGE_NAME> --query 'id' -o tsv)
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal \
    --role "Storage Blob Data Owner" --scope $storageId

# Create the function app in a Flex Consumption plan that uses the user-assigned managed identity
# to access the deployment share.
az functionapp create --resource-group "AzureFunctionsQuickstart-rg" --name <APP_NAME> --flexconsumption-location <REGION> \
    --runtime <LANGUAGE> --runtime-version <LANGUAGE_VERSION> --storage-account <STORAGE_NAME> \
    --deployment-storage-auth-type UserAssignedIdentity --deployment-storage-auth-value <USER_NAME>

# Create a role assignment (Monitoring Metrics Publisher) in Application Insights for the user identity
appInsights=$(az monitor app-insights component show --resource-group "AzureFunctionsQuickstart-rg" \
    --app <APP_NAME> --query "id" --output tsv)
az role assignment create --role "Monitoring Metrics Publisher" --assignee $principalId --scope $appInsights

# Update app settings to use managed identities for all connections
clientId=$(az identity show --name func-host-storage-user --resource-group AzureFunctionsQuickstart-rg \
    --query 'clientId' -o tsv)
az functionapp config appsettings set --name <APP_NAME> --resource-group "AzureFunctionsQuickstart-rg" \
    --settings AzureWebJobsStorage__accountName=<STORAGE_NAME> AzureWebJobsStorage__credential=managedidentity \
    AzureWebJobsStorage__clientId=$clientId APPLICATIONINSIGHTS_AUTHENTICATION_STRING="ClientId=$clientId;Authorization=AAD"
az functionapp config appsettings delete --name <APP_NAME> --resource-group "AzureFunctionsQuickstart-rg" --setting-names AzureWebJobsStorage

# echo "Deleting all resources"
# az group delete --name "AzureFunctionsQuickstart-rg" -y
```