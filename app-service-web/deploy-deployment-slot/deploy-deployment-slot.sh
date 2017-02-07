#!/bin/bash

webappname=mywebapp$RANDOM
githubrepo="<URL of your repo here>"

# Create a resource group. For possible values of --location, run "az appservice list-locations"
az group create --location westeurope --name $webappname

# Create an App Service plan in FREE tier.
az appservice plan create --name $webappname --resource-group $webappname --sku FREE

# Create a web app.
az appservice web create --name $webappname --resource-group $webappname --plan $webappname

# Upgrade App Service plan to STANDARD tier (minimum required by deployment slots)
az appservice plan update --name $webappname --resource-group $webappname --sku S1

#Create a deployment slot with the name "staging".
az appservice web deployment slot create --name $webappname --resource-group $webappname --slot staging

# Configure GitHub deployment from your GitHub repo and deploy once.
az appservice web source-control config --name $webappname --resource-group $webappname --slot staging \
--repo-url $githubrepo --branch master

# Browse to the deployed web app on staging. If you don't see your app, deployment may be in progress. Rerun this in a few minutes.
az appservice web browse --name $webappname --resource-group $webappname --slot staging

# Swap the verified/warmed up staging slot into production.
az appservice web deployment slot swap --name $webappname --resource-group $webappname --slot staging

# Browse to the production slot. 
az appservice web browse --name $webappname --resource-group $webappname
