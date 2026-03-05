#!/bin/bash

# This script creates a function app in a Flex Consumption plan with VNet integration
# and restricts the storage account behind private endpoints so it's only accessible
# from inside the virtual network. Uses managed identity for all connections.
# Function app, storage account, and user identity names must be unique.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="create-function-app-vnet-storage"
storage="msdocsaccount$randomIdentifier"
userIdentity="msdocs-managed-identity-$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
vnetName="msdocs-vnet-$randomIdentifier"
subnetFunctions="subnet-functions"
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

# Create a virtual network with a default subnet
echo "Creating $vnetName"
az network vnet create --name $vnetName --resource-group $resourceGroup --location "$location" \
    --address-prefix 10.0.0.0/16

# Create a subnet for the function app with delegation to Microsoft.App/environments
# (required for Flex Consumption VNet integration)
echo "Creating $subnetFunctions with Microsoft.App/environments delegation"
az network vnet subnet create --name $subnetFunctions --resource-group $resourceGroup \
    --vnet-name $vnetName --address-prefix 10.0.1.0/24 \
    --delegations Microsoft.App/environments

# Create a subnet for private endpoints
echo "Creating $subnetPrivateEndpoints for private endpoints"
az network vnet subnet create --name $subnetPrivateEndpoints --resource-group $resourceGroup \
    --vnet-name $vnetName --address-prefix 10.0.2.0/24

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

# Get the function app subnet ID
functionSubnetId=$(az network vnet subnet show --name $subnetFunctions --resource-group $resourceGroup \
    --vnet-name $vnetName --query 'id' -o tsv)

# Create the function app in a Flex Consumption plan with VNet integration.
# The --virtual-network-subnet-id parameter configures outbound VNet integration,
# which routes all outbound traffic from the function app through the VNet.
echo "Creating $functionApp with VNet integration"
az functionapp create --resource-group $resourceGroup --name $functionApp --flexconsumption-location $location \
    --runtime $languageWorker --runtime-version $languageVersion --storage-account $storage \
    --deployment-storage-auth-type UserAssignedIdentity --deployment-storage-auth-value $userIdentity \
    --virtual-network-subnet-id $functionSubnetId

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

# Create private endpoints for the storage account (blob, queue, table).
# These allow the VNet-integrated function app to access the storage account
# over the private network after public access is disabled.
for subresource in blob queue table; do
    echo "Creating private endpoint for storage $subresource"
    az network private-endpoint create --name "pe-$storage-$subresource" \
        --resource-group $resourceGroup --vnet-name $vnetName --subnet $subnetPrivateEndpoints \
        --private-connection-resource-id $storageId \
        --group-id $subresource --connection-name "conn-$subresource" --location "$location"
done

# Create private DNS zones and link them to the VNet so the function app
# resolves storage endpoints to their private IP addresses.
for zone in blob queue table; do
    dnsZoneName="privatelink.$zone.core.windows.net"
    echo "Creating private DNS zone $dnsZoneName"
    az network private-dns zone create --resource-group $resourceGroup --name $dnsZoneName
    az network private-dns link vnet create --resource-group $resourceGroup \
        --name "link-$zone" --zone-name $dnsZoneName --virtual-network $vnetName \
        --registration-enabled false
    az network private-endpoint dns-zone-group create --resource-group $resourceGroup \
        --endpoint-name "pe-$storage-$zone" --name "default" \
        --private-dns-zone $dnsZoneName --zone-name $zone
done

# Now that private endpoints and DNS are configured, disable public network access
# on the storage account. The function app can still reach storage through the VNet.
echo "Restricting $storage to private endpoint access only"
az storage account update --name $storage --resource-group $resourceGroup \
    --default-action Deny --public-network-access Disabled

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
