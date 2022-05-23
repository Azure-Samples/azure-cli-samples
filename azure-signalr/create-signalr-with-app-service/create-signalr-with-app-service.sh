#!/bin/bash
# Passed validation in Cloud Shell on 3/30/2022

# <FullScript>
# Create a SignalR Service with an App Service

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azure-signalr-rg-$randomIdentifier"
tag="create-signal-service-with-app-service"
signalRSvc="msdocs-signalr-svc-$randomIdentifier"
webApp="msdocs-web-app-signalr-$randomIdentifier"
appSvcPlan="msdocs-app-svc-plan-$randomIdentifier"
signalRSku="Standard_S1"
unitCount="1"
serviceMode="Default"
planSku="Free"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create the Azure SignalR Service resource
echo "Creating $signalRSvc"
az signalr create \
  --name $signalRSvc \
  --resource-group $resourceGroup \
  --sku $signalRSku \
  --unit-count $unitCount \
  --service-mode $serviceMode

# Create an App Service plan.
echo "Creating $appSvcPlan"
az appservice plan create --name $appSvcPlan --resource-group $resourceGroup --sku $planSku

# Create the Web App
echo "Creating $webApp"
az webapp create --name $webApp --resource-group $resourceGroup --plan $appSvcPlan

# Get the SignalR primary connection string
primaryConnectionString=$(az signalr key list --name $signalRSvc \
  --resource-group $resourceGroup --query primaryConnectionString -o tsv)
echo $primaryConnectionString

# Add an app setting to the web app for the SignalR connection
az webapp config appsettings set --name $webApp --resource-group $resourceGroup \
  --settings "AzureSignalRConnectionString=$primaryConnectionString" 
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
