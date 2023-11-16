#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Scale an App Service app manually
#
# This sample script creates a resource group, 
# an App Service plan, and an app. It then scales
# the App Service plan from a single instance to multiple instances.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="scale-manual.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in Basic tier
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --location "$location" --sku B1

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

# Scale Web App to 2 Workers
az appservice plan update --number-of-workers 2 --name $appServicePlan --resource-group $resourceGroup
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
