#!/bin/bash

# Update the following variables for your own settings:
resourceGroup=build2018
amsAccountName=build18
assetName="myAsset-uniqueID"
expiry=$(date -u +"%Y-%m-%dT%TZ" -d "+23 hours")

# Create a Media Services Asset to upload content to.
# In the v3 API, Asset names are unique ARM resource identifiers and must be unique to the account.
# It's recommended to use short unique IDs or GUIDs to keep the names unique to the account.
az ams asset create \
    -n $assetName \
    -a $amsAccountName \
    -g $resourceGroup \

# Get the SAS URLs to upload content to the container for the Asset
# Default is 23 hour expiration, but you can adjust with the --expiry flag. 
# Max supported is 24 hours. 
az ams asset get-sas-urls \
    -n $assetName \
    -a $amsAccountName \
    -g $resourceGroup \
    --expiry  $expiry\
    --permissions ReadWrite \

# Use the az storage modules to upload a local file to the container using the SAS URL from previous step.
# If you are logged in already to the subscription with access to the storage account, you do not need to use the --sas-token at all. Just eliminate it below.
# The container name is in the SAS URL path, and should be set with the -c option.
# Use the -f option to point to a local file on your machine.
# Use the -n option to name the blob in storage.
# Use the --account-name option to point to the storage account name to use 
# Use the --sas-token option to place the SAS token after the query string from previous step. 
# NOTE that the SAS Token is only good for up to 24 hours max. 

#   az storage blob upload \
#       -c asset-84045780-a71c-4511-801b-711b1a2e76b2 \
#       -f C:\Videos\ignite-short.mp4 \
#       -n ignite-short.mp4 \
#       --account-name mconverticlitest0003 \
#       --sas-token "?sv=2015-07-08&sr=c&sig=BvMXDCOjR%2FOP2%2FYi6lVknC4Gcq7fIun5tst8jgED7zY%3D&se=2018-04-25T00:00:00Z&sp=rwl" \

echo "press  [ENTER]  to continue."
read continue