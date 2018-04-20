#!/bin/bash

# Generate a unique suffix for the service name
let randomNum=$RANDOM*$RANDOM

# Generate unique names for SignalR service, resource group, 
# app service, and app service plan
myResourceName=SignalRTestSvc$randomNum
myResourceGroupName=$signalrsvcname"Group"
myAppSvcName=SignalRTestWebApp$randomNum
myAppSvcPlanName="SignalRTestWebApp"$randomNum"Plan"

# Create resource group 
az group create --name $myResourceGroupName --location eastus

# Create the Azure SignalR Service resource
az signalr create \
  --name $myResourceName \
  --resource-group $myResourceGroupName \
  --sku Basic_DS2 \
  --unit-count 1

# Create an App Service plan.
az appservice plan create --name $myAppSvcPlanName --resource-group $myResourceGroupName --sku FREE

# Create the Web App
az webapp create --name $myAppSvcName --resource-group $myResourceGroupName --plan $myAppSvcPlanName  