#!/bin/bash
# Passed validation in Cloud Shell on 3/28/2022

# <FullScript>
# Create Event Grid custom topic

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
subscriptionId="$(az account show --query id -o tsv)"
resourceGroup="msdocs-event-grid-rg-$randomIdentifier"
tags="event-grid"
topic="msdocs-event-grid-topic-$randomIdentifier"
eventSubscription="msdocs-event-subscription-$randomIdentifier"
storageName="msdocsstorage$randomIdentifier"

# Create a resource group
echo "Creating  in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create custom topic
echo "Creating $topic"
az eventgrid topic create \
--resource-group $resourceGroup \
--name $topic \
--location "$location"

# Retrieve endpoint and key to use when publishing to the topic
endpoint=$(az eventgrid topic show --name $topic -g $resourceGroup --query "endpoint" --output tsv)
key=$(az eventgrid topic key list --name $topic -g $resourceGroup --query "key1" --output tsv)
echo $endpoint
echo $key

# Subscribe to the Azure subscription.
echo "Creating $eventSubscription"
az eventgrid event-subscription create \
--name $eventSubscription --endpoint $endpoint

az eventgrid event-subscription create \
--name $eventSubscription \
--endpoint $endpoint \
--source-resource-id /subscriptions/$subscriptionId

# Create the Blob storage account. 
az storage account create \
  --name $storageName \
  --location "$location" \
  --resource-group $resourceGroup \
  --sku Standard_LRS \
  --kind BlobStorage \
  --access-tier Hot

# Get the resource ID of the Blob storage account.
storageId=$(az storage account show --name $storageName --resource-group $resourceGroup --query id --output tsv)
echo $storageId
# Subscribe to the Blob storage account. 
az eventgrid event-subscription create \
  --source-resource-id $storageId \
  --name demoSubToStorage \
  --endpoint $endpoint


# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
