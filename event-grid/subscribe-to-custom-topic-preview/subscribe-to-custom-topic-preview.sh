#!/bin/bash

# You must have the latest version of the Event Grid preview extension.
# If you have not installed previously:
# az extension add -n eventgrid
# If you have installed previously:
# az extension update -n eventgrid

# Provide the name of the topic you are subscribing to
myTopic=demoContosoTopic

# Provide the name of the resource group containing the custom topic
resourceGroup=demoResourceGroup

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Select the Azure subscription that contains the custom topic.
az account set --subscription "<name or ID of the subscription>"

# Get the resource ID of the custom topic
topicID=$(az eventgrid topic show --name $myTopic -g $resourceGroup --query id --output tsv)

# Subscribe to the custom event. Include the resource group that contains the custom topic.
az eventgrid event-subscription create \
  --source-resource-id $topicID \
  --name demoSubscription \
  --endpoint $myEndpoint