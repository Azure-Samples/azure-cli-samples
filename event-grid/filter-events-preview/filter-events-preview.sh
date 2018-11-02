#!/bin/bash

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Provide the name of the custom topic to create
topicName=<your-topic-name>

# Provide the name of the resource group to contain the custom topic
myResourceGroup=demoResourceGroup

# Select the Azure subscription that contains the resource group.
az account set --subscription "<name or ID of the subscription>"

# Create the resource group
az group create -n $myResourceGroup -l eastus2

# Create custom topic
az eventgrid topic create --name $topicName -l eastus2 -g $myResourceGroup

# Get resource ID of custom topic
topicid=$(az eventgrid topic show --name $topicName -g $myResourceGroup --query id --output tsv)

# Subscribe to the custom topic. Filter based on a value in the event data.
az eventgrid event-subscription create \
  --source-resource-id $topicid \
  -n demoAdvancedFilterSub \
  --advanced-filter data.color stringin blue red green \
  --endpoint $endpointURL