#!/bin/bash

# Provide the name of the topic you are subscribing to
myTopic=demoContosoTopic

# Provide the name of the resource group containing the custom topic
resourceGroup=demoResourceGroup

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Select the Azure subscription that contains the custom topic.
az account set --subscription "<name or ID of the subscription>"

# Subscribe to the custom event. Include the resource group that contains the custom topic.
az eventgrid event-subscription create \
  --resource-group $resourceGroup \
  --topic-name $myTopic  \
  --name demoSubscription \
  --endpoint $myEndpoint