#!/bin/bash

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Select the Azure subscription you want to subscribe to.
az account set --subscription "Contoso Subscription"

# Subscribe to the Azure subscription. The command creates the subscription for the currently selected Azure subscription. 
az eventgrid event-subscription create --name demoSubscriptionToAzureSub --endpoint $myEndpoint