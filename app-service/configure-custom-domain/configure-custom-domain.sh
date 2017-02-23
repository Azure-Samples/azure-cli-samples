#!/bin/bash

fqdn=<Replace with your fully-qualified domain name>
webappname=mywebapp$RANDOM

# Create a resource group.
az group create --location westeurope --name $webappname

# Create an App Service plan in FREE tier.
az appservice plan create --name $webappname --resource-group $webappname --sku FREE

# Create a web app.
az appservice web create --name $webappname --resource-group $webappname \
--plan $webappname

# Upgrade App Service plan to SHARED tier (minimum required by custom domains).
az appservice plan update --name $webappname --resource-group $webappname --sku SHARED

# Map your prepared custom domain name to the web app.
az appservice web config hostname add --webapp $webappname --resource-group $webappname \
--name $fqdn

# Browse to the production slot. 
az appservice web browse --name $webappname --resource-group $webappname
