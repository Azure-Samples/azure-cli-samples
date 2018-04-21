#!/bin/bash

# Generate a unique suffix for the service name
let randomNum=$RANDOM*$RANDOM

# Generate unique names for the SignalR service, resource group, 
# app service, and app service plan
SignalRName=SignalRTestSvc$randomNum
#resource name must be lowercase
mySignalRSvcName=${SignalRName,,}
myResourceGroupName=$SignalRName"Group"
myWebAppName=SignalRTestWebApp$randomNum
myAppSvcPlanName=$myAppSvcName"Plan"

# Create resource group 
az group create --name $myResourceGroupName --location eastus

# Create the Azure SignalR Service resource
signalRresource=$(az signalr create \
  --name $mySignalRSvcName \
  --resource-group $myResourceGroupName \
  --sku Basic_DS2 \
  --unit-count 1)
echo "$signalRresource"

# Create an App Service plan.
az appservice plan create --name $myAppSvcPlanName --resource-group $myResourceGroupName --sku FREE

# Create the Web App
az webapp create --name $myWebAppName --resource-group $myResourceGroupName --plan $myAppSvcPlanName  

# Get the SignalR primary key 
signalRkeys=$(az signalr key list --name $mySignalRSvcName --resource-group $myResourceGroupName)
signalRprimarykey=$(echo "$signalRkeys" | grep -Po '(?<="primaryKey": ")[^"]*')

# Form the connection string for use in your application
signalRhostname=$(echo "$signalRresource" | grep -Po '(?<="hostName": ")[^"]*')
connstring="Endpoint=https://$signalRhostname;AccessKey=$signalRprimarykey;"

#Add an app setting to the web app for the SignalR connection
az webapp config appsettings set --name $myWebAppName --resource-group $myResourceGroupName \
  --settings "SignalRConnectionString=$connstring" 
