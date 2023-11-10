#!/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Create an App Service app and deploy code to a staging environment
#
# This sample script creates an app in App Service with an additional 
# deployment slot called "staging", and then deploys a sample app to 
# the "staging" slot.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="deploy-deployment-slot.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"
gitrepo=https://github.com/Azure-Samples/php-docs-hello-world # Replace with your public GitHub repo URL

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in STANDARD tier (minimum required by deployment slots).
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --location "$location" \
--sku S1

# Create a web app
echo "Creating $webapp"
az webapp create --name $webapp --plan $appServicePlan --resource-group $resourceGroup

# Create a deployment slot with the name "staging".
az webapp deployment slot create --name $webapp --resource-group $resourceGroup --slot staging

# Deploy sample code to "staging" slot from GitHub.
az webapp deployment source config --name $webapp --resource-group $resourceGroup --slot staging --repo-url $gitrepo --branch master --manual-integration

# Copy the result of the following command into a browser to see the staging slot.
site="http://$webapp-staging.azurewebsites.net"
echo $site
curl "$site"

# Swap the verified/warmed up staging slot into production.
az webapp deployment slot swap --name $webapp --resource-group $resourceGroup \
--slot staging

# Copy the result of the following command into a browser to see the web app in the production slot.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
