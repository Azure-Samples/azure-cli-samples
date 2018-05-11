#!/bin/bash

# WARNING:  This shell script requires Python 3 to be installed to parse JSON. 

# Update the following variables for your own settings:
resourceGroup=build2018
amsAccountName=build18
assetName="myAsset-uniqueID"
locatorName="myStreamingLocator"
streamingPolicyName="Predefined_DownloadAndClearStreaming"
#contentPolicyName=""

# Delete the locator if it already exists
az ams streaming locator delete \
    -a $amsAccountName \
    -g $resourceGroup \
    -n $locatorName \

# Create a new Streaming Locator. Modify the assetName variable to point to the Asset you want to publish
# This uses the predefined Clear Streaming Only policy, which allows for unencypted deliver over HLS, Smooth and DASH protocols. 
az ams streaming locator create \
    -a $amsAccountName \
    -g $resourceGroup \
    --asset-name $assetName \
    -n $locatorName \
    --streaming-policy-name $streamingPolicyName \
    #--end-time 2100-10-10T00:00:00Z \
    #--start-time 2018-04-28T00:00:00Z \
    #--content-policy-name $contentPolicyName \

# List the Streaming Endpoints on the account. If this is a new account it only has a 'default' endpoint, which may be stopped.
# To stream, you must first Start a Streaming Endpoint on your account. 
# This next commmand lists the Streaming Endpoints, and gets the value of the "hostname" property for the 'default' endpoint to be used when building
# the complete Streaming or download URL from the locator get-paths method following this.
# NOTE: This command requires Python 3.5 to be installed. 
hostName=$(az ams streaming endpoint list \
    -a $amsAccountName \
    -g $resourceGroup  | \
    python -c "import sys, json; print(json.load(sys.stdin)[0]['hostName'])")

echo -e "\n"
echo -e "Default hostname: https://"$hostName
   
# List the Streming URLs relative paths for the new locator.  You must append your Streaming Endpoint "hostname" path to these to resolve the full URL. 
# Note that the asset must have an .ismc and be encoded for Adaptive streaming in order to get Streaming URLs back. You can get download paths for any content type.
paths=$(az ams streaming locator get-paths \
    -a $amsAccountName \
    -g $resourceGroup \
    -n $locatorName )

downloadPaths=$(echo $paths | \
                python -c "import sys, json; print(json.load(sys.stdin)['downloadPaths'])" )

streamingPaths=$(echo $paths |\
                python -c "import sys, json; print(json.load(sys.stdin)['streamingPaths'])" )

echo -e "\n"
echo "DownloadPaths:" 
echo $downloadPaths
echo -e "\n"
echo "StreamingPaths:"
echo $streamingPaths

echo "press  [ENTER]  to continue."
read continue