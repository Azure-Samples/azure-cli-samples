#!/bin/bash

webappname=mywebapp$RANDOM
gitrepo="<URL of your repo here>"

# Create a resource group. For possible values of --location, run "az appservice list-locations"
az group create --location westeurope --name $webappname

# Create an App Service plan in `FREE` tier.
az appservice plan create --name $webappname --resource-group $webappname --sku FREE

# Create a web app.
az appservice web create --name $webappname --resource-group $webappname --plan $webappname

# Configure GitHub deployment from your GitHub repo and deploy once.
az appservice web source-control config --name $webappname --resource-group $webappname \
--repo-url $gitrepo --branch master

#### What are the requirements for setting up GitHub? Does the terminal need to be already logged into GitHub? #####

# Browse to the deployed web app. If you don't see your app, deployment may be in progress. Rerun this in a few minutes.
az appservice web browse --name $webappname --resource-group $webappname
