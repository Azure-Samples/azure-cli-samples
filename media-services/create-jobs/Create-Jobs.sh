#!/bin/bash

# Update the following variables for your own settings:
resourceGroup=build2018
amsAccountName=build18
outputAssetName=myOutputAsset
transformName=audioAnalyzerTransform

# NOTE: First create the Transforms in the Create-Transform.sh for these jobs to work!

# Create a Media Services Asset to output the job results to.
az ams asset create \
    -n $outputAssetName \
    -a $amsAccountName \
    -g $resourceGroup \

# Submit a Job to a simple encoding Transform using HTTPs URL
az ams job start \
    --name myFirstJob_007 \
    --transform-name $transformName \
    --base-uri 'https://nimbuscdn-nimbuspm.streaming.mediaservices.windows.net/2b533311-b215-4409-80af-529c3e853622/' \
    --files 'Ignite-short.mp4' \
    --output-asset-names $outputAssetName \
    -a $amsAccountName \
    -g $resourceGroup \

echo "press  [ENTER]  to continue."
read continue