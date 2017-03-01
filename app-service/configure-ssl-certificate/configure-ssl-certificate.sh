#!/bin/bash

pfxPath=<Replace with path to your .PFX file>
pfxPassword=<Replace with your .PFX password>
webappname=mywebapp$RANDOM

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an App Service plan in Basic tier (minimum required by custom domains).
az appservice plan create --name $webappname --resource-group myResourceGroup --sku B1

# Create a web app.
az appservice web create --name $webappname --resource-group myResourceGroup \
--plan $webappname

# Upload the SSL certificate and get the thumbprint.
thumprint=$(az appservice web config ssl upload --certificate-file $pfxPath \
--certificate-password $pfxPassword --name $webappname --resource-group myResourceGroup \
--query thumbprint --output tsv)

az appservice web config ssl bind --certificate-thumbprint $thumbprint --ssl-type SNI \
--name $webappname --resource-group myResourceGroup

echo "You can now browse to https://<your-app's-domain-name>"
