#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Map a custom domain to an App Service app
#
# This sample script creates an app in App Service with its
# related resources, and then maps www.<yourdomain> to it.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="configure-custom-domain-webapp-only.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in SHARED tier (minimum required by custom domains).
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku SHARED

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

# Copy the result of the following command into a browser to see the static HTML site.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site"
# </FullScript>

# See app-service/scripts/cli-configure-custom-domain.md for additional steps

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
