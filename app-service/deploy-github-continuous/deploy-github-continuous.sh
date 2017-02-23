#!/bin/bash

gitrepo=<Replace with your GitHub repo URL>
token=<Replace with a GitHub access token>
webappname=mywebapp$RANDOM

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an App Service plan in `FREE` tier.
az appservice plan create --name $webappname --resource-group myResourceGroup --sku FREE

# Create a web app.
az appservice web create --name $webappname --resource-group myResourceGroup --plan $webappname

# Configure continuous deployment from GitHub. 
# --git-token parameter is required only once per Azure account (Azure remembers token).
az appservice web source-control config --name $webappname --resource-group myResourceGroup \
--repo-url $gitrepo --branch master --git-token $token

# Browse to the web app.
az appservice web browse --name $webappname --resource-group myResourceGroup
