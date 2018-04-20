#!/bin/bash

# Generate a unique suffix for the service name
let randomNum=$RANDOM*$RANDOM

# Generate a unique service and group name with the suffix
myResourceName=SignalRTestSvc$randomNum
myResourceGroupName=$signalrsvcname"Group"

# Create resource group 
az group create --name $myResourceGroupName --location eastus

# Create the Azure SignalR Service resource
az signalr create \
  --name $myResourceName \
  --resource-group $myResourceGroupName \
  --sku Basic_DS2 \
  --unit-count 1