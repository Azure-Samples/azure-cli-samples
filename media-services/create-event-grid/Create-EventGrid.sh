#!/bin/bash

# Update the following variables for your own settings:
resourceGroup=build2018
amsAccountName=build18
webhookEndpoint="https://johndeueventgrid.azurewebsites.net/api/GenericWebhookCSharp1?code=wZZbhwxtS///qsCHJAEv/SJMagaQDlAOCLKeBqnmC1axKipM0EayXw==&clientId=default"

# Create an account level Event Grid subscription for Job State Changes.
# ResourceId variable should be set to the full ARM resource URL for the media account.
# Endpoint must point to a valid webhook that is enabled to respond to the EventGrid validation event.
az eventgrid event-subscription create \
	--name myEvent \
	--resource-id //subscriptions/35c2594a-23da-4fce-b59c-f6fb9513eeeb/resourceGroups/build2018/providers/Microsoft.Media/mediaservices/build18 \
	--included-event-types "Microsoft.Media.JobStateChange" \
	--endpoint $webhookEndpoint \

echo "press  [ENTER]  to continue."
read continue