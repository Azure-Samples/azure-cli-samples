#!/bin/bash
# Passed validation in Cloud Shell on 3/30/2022

# <FullScript>
# Create a SignalR Service

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azure-signalr-rg-$randomIdentifier"
tag="create-signal-service-and-group"
signalRSvc=msdocs-signalr-svc-$randomIdentifier
signalRSku="Standard_S1"
unitCount="1"
serviceMode="Default"

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

# Get the SignalR primary connection string 
primaryConnectionString=$(az signalr key list --name $signalRSvc \
  --resource-group $resourceGroup --query primaryConnectionString -o tsv)

echo "$primaryConnectionString"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
