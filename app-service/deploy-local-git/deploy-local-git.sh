#!/bin/bash

gitdirectory=<Replace with path to local Git repo>
webappname=mywebapp$RANDOM

# Log in to Azure
az login

# Create a resource group.
az group create --location westeurope --name $webappname

# Create an App Service plan in FREE tier.
az appservice plan create --name $webappname --resource-group $webappname --sku FREE

# Create a web app.
az appservice web create --name $webappname --resource-group $webappname --plan $webappname

# Configure local Git
az appservice web source-control config-local-git --name $webappname \
--resource-group $webappname

# Get app-level credential information
uri=$(az appservice web deployment list-site-credentials --name $webappname \
--resource-group $webappname --query scmUri)

# Extract the Azure repository URL from the JSON output
uri=$(echo "${uri:1:${#uri}-2}")

# Add the Azure remote to your local Git respository and push your code
#### This method saves your password in the git remote. You can use a Git credential manager to secure your password instead.
cd $gitdirectory
git remote add azure $uri
git push azure master

# Browse to the deployed web app.
az appservice web browse --name $webappname --resource-group $webappname

