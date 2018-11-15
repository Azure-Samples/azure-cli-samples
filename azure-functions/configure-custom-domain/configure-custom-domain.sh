#!/bin/bash

# Function app and storage account names must be unique.
storageName=mystorageaccount$RANDOM
functionAppName=myconsumptionfunc$RANDOM

# TODO:
# Before starting, go to your DNS configuration UI for your custom domain and follow the 
# instructions at https://aka.ms/appservicecustomdns to configure an A record 
# and point it your web app's default domain name. 
fqdn=<Replace with www.{yourcustomdomain}>

# Create a resource resourceGroupName
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create an App Service plan in Basic tier (minimum required by custom domains).
az appservice plan create \
  --name FunctionAppWithAppServicePlan \
  --resource-group myResourceGroup \
  --location westeurope \
  --sku B1

# Create a Function App
az functionapp create \
  --name $functionAppName \
  --storage-account $storageName \
  --plan FunctionAppWithAppServicePlan \
  --resource-group myResourceGroup
  
# Map your prepared custom domain name to the function app.
az functionapp config hostname add \
  --hostname $functionAppName \
  --resource-group myResourceGroup \
  --name $fqdn

echo "You can now browse to http://$fqdn"
