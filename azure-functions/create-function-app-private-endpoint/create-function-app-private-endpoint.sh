#!/bin/bash

# This script creates a function app in a Flex Consumption plan and restricts
# inbound access using a private endpoint, so the function app's HTTP endpoints
# can only be called from inside the virtual network.
# Function app, storage account, and user identity names must be unique.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="create-function-app-private-endpoint"
storage="msdocsaccount$randomIdentifier"
userIdentity="msdocs-managed-identity-$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
vnetName="msdocs-vnet-$randomIdentifier"
subnetPrivateEndpoints="subnet-private-endpoints"
skuStorage="Standard_LRS"
functionsVersion="4"
languageWorker="python"
languageVersion="3.11"

# Install the Application Insights extension
az extension add --name application-insights

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network
echo "Creating $vnetName"
az network vnet create --name $vnetName --resource-group $resourceGroup --location "$location" \
    --address-prefix 10.0.0.0/16

# Create a subnet for private endpoints
echo "Creating $subnetPrivateEndpoints for private endpoints"
az network vnet subnet create --name $subnetPrivateEndpoints --resource-group $resourceGroup \
    --vnet-name $vnetName --address-prefix 10.0.1.0/24

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

# Create a private endpoint in the VNet for the function app.
# This gives the function app a private IP address inside the VNet.
functionAppId=$(az functionapp show --name $functionApp --resource-group $resourceGroup --query 'id' -o tsv)
echo "Creating private endpoint for $functionApp"
az network private-endpoint create --name "pe-$functionApp" \
    --resource-group $resourceGroup --vnet-name $vnetName --subnet $subnetPrivateEndpoints \
    --private-connection-resource-id $functionAppId \
    --group-id sites --connection-name "conn-functionapp" --location "$location"

# Create a private DNS zone for Azure Functions and link it to the VNet.
# This allows clients inside the VNet to resolve the function app's hostname
# to its private IP address.
dnsZoneName="privatelink.azurewebsites.net"
echo "Creating private DNS zone $dnsZoneName"
az network private-dns zone create --resource-group $resourceGroup --name $dnsZoneName
az network private-dns link vnet create --resource-group $resourceGroup \
    --name "link-functionapp" --zone-name $dnsZoneName --virtual-network $vnetName \
    --registration-enabled false
az network private-endpoint dns-zone-group create --resource-group $resourceGroup \
    --endpoint-name "pe-$functionApp" --name "default" \
    --private-dns-zone $dnsZoneName --zone-name sites

# Disable public network access on the function app.
# After this, the function app's HTTP endpoints are only reachable
# from inside the VNet through the private endpoint.
echo "Disabling public access on $functionApp"
az resource update --resource-group $resourceGroup --name $functionApp \
    --resource-type "Microsoft.Web/sites" \
    --set properties.publicNetworkAccess=Disabled

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
