#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Create an ASP.NET Core app in a Docker container from Docker Hub
#
# This sample script creates a resource group, a Linux App Service plan,
# and an app. It then deploys an ASP.NET Core application using a Docker Container.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="deploy-linux-docker-app-only.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in S1 tier
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku S1 --is-linux

# Create a web app. To see list of available runtimes, run 'az webapp list-runtimes --linux'
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan  --runtime "NODE|14-lts"

# Copy the result of the following command into a browser to see the static HTML site.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site"
# </FullScript>

# See app-service/scripts/cli-linux-docker-aspnetcore.md for additional steps

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
