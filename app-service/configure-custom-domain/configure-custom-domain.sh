#!/bin/bash

fqdn=<Replace with www.{yourdomain}>
webappname=mywebapp$RANDOM

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an App Service plan in SHARED tier (minimum required by custom domains).
az appservice plan create --name $webappname --resource-group myResourceGroup --sku SHARED

# Create a web app.
az appservice web create --name $webappname --resource-group myResourceGroup \
--plan $webappname

echo "Configure a CNAME record that maps $fqdn to $webappname.azurewebsites.net"
read -p "Press [Enter] key when ready ..."

# Before continuing, go to your DNS configuration UI for your custom domain and follow the 
# instructions at https://aka.ms/appservicecustomdns to configure a CNAME record for the 
# hostname "www" and point it your web app's default domain name.

# Map your prepared custom domain name to the web app.
az appservice web config hostname add --webapp $webappname --resource-group myResourceGroup \
--name $fqdn

echo "You can now browse to http://$fqdn"
