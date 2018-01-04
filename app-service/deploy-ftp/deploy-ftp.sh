#!/bin/bash

warurl=https://raw.githubusercontent.com/Azure-Samples/html-docs-hello-world/master/index.html
webappname=mywebapp$RANDOM

# Download sample static HTML page
curl $warurl --output index.html

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an App Service plan in `FREE` tier.
az appservice plan create --name myAppServicePlan --resource-group myResourceGroup --sku FREE

# Create a web app.
az webapp create --name $webappname --resource-group myResourceGroup --plan myAppServicePlan

# Get FTP publishing profile and query for publish URL and credentials
creds=($(az webapp deployment list-publishing-profiles --name $webappname --resource-group myResourceGroup \
--query "[?contains(publishMethod, 'FTP')].[publishUrl,userName,userPWD]" --output tsv))

# Use cURL to perform FTP upload. You can use any FTP tool to do this instead. 
curl -T index.html -u ${creds[1]}:${creds[2]} ${creds[0]}/

# Copy the result of the following command into a browser to see the static HTML site.
echo http://$webappname.azurewebsites.net
