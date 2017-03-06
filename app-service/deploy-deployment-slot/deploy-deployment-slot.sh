#!/bin/bash

gitrepo=<Replace with a public GitHub repo URL. e.g. https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git>
webappname=mywebapp$RANDOM

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an App Service plan in STANDARD tier (minimum required by deployment slots).
az appservice plan create --name $webappname --resource-group myResourceGroup --sku S1

# Create a web app.
az appservice web create --name $webappname --resource-group myResourceGroup \
--plan $webappname

#Create a deployment slot with the name "staging".
az appservice web deployment slot create --name $webappname --resource-group myResourceGroup \
--slot staging

# Deploy sample code to "staging" slot from GitHub.
az appservice web source-control config --name $webappname --resource-group myResourceGroup \
--slot staging --repo-url $gitrepo --branch master --manual-integration

# Browse to the deployed web app on staging. Deployment may be in progress, so rerun this if necessary.
az appservice web browse --name $webappname --resource-group myResourceGroup --slot staging

# Swap the verified/warmed up staging slot into production.
az appservice web deployment slot swap --name $webappname --resource-group myResourceGroup \
--slot staging

# Browse to the production slot. 
az appservice web browse --name $webappname --resource-group myResourceGroup
