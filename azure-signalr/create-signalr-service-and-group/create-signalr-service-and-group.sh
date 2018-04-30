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

# Create the Azure SignalR Service resource and query the hostName
signalRhostname=$(az signalr create \
  --name $mySignalRSvcName \
  --resource-group $myResourceGroupName \
  --sku Basic_DS2 \
  --unit-count 1 \
  --query hostName \
  -o tsv)

# Get the SignalR primary key 
signalRprimarykey=$(az signalr key list --name $mySignalRSvcName \
  --resource-group $myResourceGroupName --query primaryKey -o tsv)

# Form the connection string for use in your application
connstring="Endpoint=https://$signalRhostname;AccessKey=$signalRprimarykey;"
echo "$connstring"  
