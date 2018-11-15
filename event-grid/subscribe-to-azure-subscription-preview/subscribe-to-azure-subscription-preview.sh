#!/bin/bash

# You must have the latest version of the Event Grid preview extension.
# If you have not installed previously:
# az extension add -n eventgrid
# If you have installed previously:
# az extension update -n eventgrid

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Select the Azure subscription you want to subscribe to.
az account set --subscription "<name or ID of the subscription>"

# Get the subscription ID
subID=$(az account show --query id --output tsv)

# Subscribe to the Azure subscription. The command creates the subscription for the currently selected Azure subscription. 
az eventgrid event-subscription create --name demoSubscriptionToAzureSub --endpoint $myEndpoint --source-resource-id /subscriptions/$subID