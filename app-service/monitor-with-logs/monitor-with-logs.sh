#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Monitor an App Service app with web server logs
#
# This sample script creates a resource group, 
# App Service plan, and app, and configures the 
# app to enable web server logs. It then downloads
# the log files for review.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="monitor-with-logs.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service Plan
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup

# Create a Web App and save the URL
echo "Creating $webapp"
url=$(az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan --query defaultHostName | sed -e 's/^"//' -e 's/"$//')

# Enable all logging options for the Web App
az webapp log config --name $webapp --resource-group $resourceGroup --application-logging azureblobstorage --detailed-error-messages true --failed-request-tracing true --web-server-logging filesystem

# Create a Web Server Log
curl -s -L $url/404

# Download the log files for review
az webapp log download --name $webapp --resource-group $resourceGroup
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
