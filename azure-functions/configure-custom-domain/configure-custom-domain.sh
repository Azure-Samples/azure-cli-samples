#!/bin/bash

# Function app and storage account names must be unique.
# When using Windows command prompt, replace $RANDOM with %RANDOM%.
storageName=mystorageaccount$RANDOM
functionAppName=myconsumptionfunc$RANDOM

# TODO:
fqdn=<Replace with www.{yourdomain}>

# Create a resource resourceGroupName
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location westeurope \
  --resource-group myResourceGroup

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

echo "Configure an A record that maps $fqdn to $functionAppName.azurewebsites.net"
read -p "Press [Enter] key when ready ..."

# Before continuing, go to your DNS configuration UI for your custom domain and follow the 
# instructions at https://aka.ms/appservicecustomdns to configure an A record 
# and point it at your function app's default domain name.

# Map your prepared custom domain name to the function app.
az functionapp config hostname add \
  --hostname $functionAppName \
  --resource-group myResourceGroup \
  --name $fqdn

echo "You can now browse to http://$fqdn"
