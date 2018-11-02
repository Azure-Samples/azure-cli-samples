#!/bin/bash

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Provide the name of the resource group to subscribe to.
myResourceGroup="<resource group name>"

# Select the Azure subscription that contains the resource group.
az account set --subscription "<name or ID of the subscription>"

# Get resource ID of the resource group.
resourceGroupID=$(az group show --name $myResourceGroup --query id --output tsv)

# Subscribe to the resource group. Provide the name of the resource group you want to subscribe to.
az eventgrid event-subscription create \
  --name demoSubscriptionToResourceGroup \
  --source-resource-id $resourceGroupID \
  --endpoint $myEndpoint
