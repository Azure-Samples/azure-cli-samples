#!/bin/bash

gitdirectory=<Replace with path to local Git repo>
username=<Replace with desired deployment username>
password=<Replace with desired deployment password>
webappname=mywebapp$RANDOM

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an App Service plan in FREE tier.
az appservice plan create --name $webappname --resource-group myResourceGroup --sku FREE

# Create a web app.
az appservice web create --name $webappname --resource-group myResourceGroup --plan $webappname

# Set the account-level deployment credentials
az appservice web deployment user set --user-name $username --password $password

# Configure local Git and get deployment URL
url=$(az appservice web source-control config-local-git --name $webappname \
--resource-group myResourceGroup --query url --output tsv)

# Add the Azure remote to your local Git respository and push your code
cd $gitdirectory
git remote add azure $url
git push azure master

# When prompted for password, use the value of $password that you specified

# Browse to the deployed web app.
az appservice web browse --name $webappname --resource-group myResourceGroup

