#!/bin/bash

# Provide the name of the topic you are subscribing to
myTopic=demoContosoTopic

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Subscribe to the custom event. Include the resource group that contains the custom topic.
az eventgrid event-subscription create \
  --resource-group eventGroup \
  --topic-name $myTopic  \
  --name demoSubscription \
  --endpoint $myEndpoint