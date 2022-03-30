#!/bin/bash
# Passed validation in Cloud Shell on 3/28/2022

# <FullScript>
# Create Event Grid custom topic

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
subscriptionId="$(az account show --query id -o tsv)"
resourceGroup="msdocs-event-grid-rg-$randomIdentifier"
tag="event-grid"
topic="msdocs-event-grid-topic-$randomIdentifier"
site="msdocs-event-grid-site-$randomIdentifier"
eventSubscription="msdocs-event-subscription-$randomIdentifier"
webappEndpoint="https://$site.azurewebsites.net/api/updates"
storage="msdocsstorage$randomIdentifier"

# Create a resource group
echo "Creating  in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Enable and then show the Event Grid resource provider
az provider register --namespace Microsoft.EventGrid
az provider show --namespace Microsoft.EventGrid --query "registrationState"

# Create custom topic
echo "Creating $topic"
az eventgrid topic create \
--resource-group $resourceGroup \
--name $topic \
--location "$location"

# Create a message endpoint
echo "Creating $site"
az deployment group create \
  --resource-group $resourceGroup \
  --template-uri "https://raw.githubusercontent.com/Azure-Samples/azure-event-grid-viewer/master/azuredeploy.json" \
  --parameters siteName=$site hostingPlanName=viewerhost

# To view your web app, navigate to https://<your-site-name>.azurewebsites.net

# Subscribe to custom topic
az eventgrid event-subscription create \
  --source-resource-id "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.EventGrid/topics/$topic" \
  --name demoViewerSub \
  --endpoint $webappEndpoint

# View your web app again to see the subscription validation event.
# Select the eye icon to expand the event data
  
# Send an event to your custom topic
url=$(az eventgrid topic show --name $topic -g $resourceGroup --query "endpoint" --output tsv)
key=$(az eventgrid topic key list --name $topic -g $resourceGroup --query "key1" --output tsv)
echo $url
echo $key
event='[ {"id": "'"$RANDOM"'", "eventType": "recordInserted", "subject": "myapp/vehicles/motorcycles", "eventTime": "'`date +%Y-%m-%dT%H:%M:%S%z`'", "data":{ "make": "Ducati", "model": "Monster"},"dataVersion": "1.0"} ]'
curl -X POST -H "aeg-sas-key: $key" -d "$event" $url

# View your web app again to see the event that you just sent
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
