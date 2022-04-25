#/bin/bash
# Passed validation in Cloud Shell on 4/24/2022

# <FullScript>
# set -e # exit if error
# Create an App Service app and configure continuous deploy with vsts
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="deploy-vsts-continuous-webapp-only.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in `FREE` tier
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku FREE

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

# Copy the result of the following command into a browser to see the static HTML site.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
