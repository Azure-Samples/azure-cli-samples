#!/usr/bin/env bash

webappname=mywebapp$RANDOM
gitdirectory="<Path to your Git directory>"
username="<Set a deployment user>"
password="<Set a deployment password>"

# Log in to Azure
az login

# Create a resource group. For possible values of --location, run "az appservice list-locations"
az group create --location westeurope --name $webappname

# Create an App Service plan in FREE tier.
az appservice plan create --name $webappname --resource-group $webappname --sku FREE

# Create a web app.
az appservice web create --name $webappname --resource-group $webappname --plan $webappname

# Set user-account-level deployment credentials
az appservice web deployment user set --user-name $username --password $password

# Configure local Git and save the JSON output
json=$(az appservice web source-control config-local-git --name $webappname --resource-group $webappname)

# Extract the Azure repository URL from the JSON output
url=$(echo $json | grep -oP '"url": "\K[^"]*')

# Add the Azure remote to your local Git respository and push your code
cd $gitdirectory
git remote add azure $url
git push azure master

#### Git will prompt you for your deployment credentials. Use $username and $password values you supplied. #####

# Browse to the deployed web app.
az appservice web browse --name $webappname --resource-group $webappname
