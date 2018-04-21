#!/bin/bash

# Generate a unique suffix for the service name
let randomNum=$RANDOM*$RANDOM

# Generate a unique service and group name with the suffix
SignalRName=SignalRTestSvc$randomNum
#resource name must be lowercase
mySignalRSvcName=${SignalRName,,}
myResourceGroupName=$SignalRName"Group"

# Create resource group 
az group create --name $myResourceGroupName --location eastus

# Create the Azure SignalR Service resource
signalRresource=$(az signalr create \
  --name $mySignalRSvcName \
  --resource-group $myResourceGroupName \
  --sku Basic_DS2 \
  --unit-count 1)
echo "$signalRresource"

# Get the SignalR primary key 
signalRkeys=$(az signalr key list --name $mySignalRSvcName --resource-group $myResourceGroupName)
signalRprimarykey=$(echo "$signalRkeys" | grep -Po '(?<="primaryKey": ")[^"]*')

# Form the connection string for use in your application
signalRhostname=$(echo "$signalRresource" | grep -Po '(?<="hostName": ")[^"]*')
connstring="Endpoint=https://$signalRhostname;AccessKey=$signalRprimarykey;"
echo "$connstring"  
