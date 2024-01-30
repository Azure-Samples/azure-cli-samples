#!/bin/bash
# Passed validation in Cloud Shell on 4/15/2022

# <FullScript>
# Create an App Service app with deployment from GitHub
#
# This sample script creates an app in App Service with its related resources,
# and then sets up continuous deployment from a GitHub repository. For GitHub 
# deployment without continuous deployment, see Create an app and deploy code
# from GitHub. 
#
# For this sample, you need:
# - A GitHub repository with application code, that you have administrative 
# permissions for. To get automatic builds, structure your repository 
# according to the Prepare your repository table.
# - A Personal Access Token (PAT) for your GitHub account.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="deploy-github.sh"
gitrepo=https://github.com/Azure-Samples/php-docs-hello-world # Replace the following URL with your own public GitHub repo URL if you have one
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in `FREE` tier.
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku FREE

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

# Deploy code from a public GitHub repository. 
az webapp deployment source config --name $webapp --resource-group $resourceGroup \
--repo-url $gitrepo --branch master --manual-integration

# Use curl to see the web app.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site" # Optionally, copy and paste the output of the previous command into a browser to see the web app
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
