#!/bin/bash

fqdn=<Replace with www.{yourdomain}>
pfxPath=<Replace with path to your .PFX file>
pfxPassword=<Replace with your .PFX password>
storageName=myfunctionappstorage$RANDOM
functionAppName=myFunctionAppName$RANDOM

# Create a resource resourceGroupName
az group create --name myResourceGroup --location westeurope

# Create an azure storage account
az storage account create --name $storageName --location westeurope \
--resource-group myResourceGroup

# Create an App Service plan in Basic tier (minimum required by custom domains).
az appservice plan create --name FunctionAppWithAppServicePlan --location westeurope \
--resource-group myResourceGroup --sku B1

# Create a Function App
az functionapp create --name $functionAppName --storage-account $storageName \
--plan FunctionAppWithAppServicePlan --resource-group myResourceGroup

echo "Configure an A record that maps $fqdn to $functionAppName.azurewebsites.net"
read -p "Press [Enter] key when ready ..."

# Before continuing, go to your DNS configuration UI for your custom domain and follow the 
# instructions at https://aka.ms/appservicecustomdns to configure an A record 
# and point it your web app's default domain name.

# Map your prepared custom domain name to the function app.
az appservice web config hostname add --webapp $functionAppName --resource-group myResourceGroup \
--name $fqdn

# Upload the SSL certificate and get the thumbprint.
thumprint=$(az appservice web config ssl upload --certificate-file $pfxPath \
--certificate-password $pfxPassword --name $functionAppName --resource-group myResourceGroup \
--query thumbprint --output tsv)

# Binds the uploaded SSL certificate to the function app.
az appservice web config ssl bind --certificate-thumbprint $thumbprint --ssl-type SNI \
--name $functionAppName --resource-group myResourceGroup

echo "You can now browse to https://$fqdn"