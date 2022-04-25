#/bin/bash
# Failed validation in Cloud Shell on 4/25/2022

# <FullScript>
# set -e # exit if error
# Create an ASP.NET Core app in a Docker container from Docker Hub
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="deploy linux docker app only"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in S1 tier
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku S1 --is-linux

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

# usage error: --runtime | --deployment-container-image-name | --multicontainer-config-type TYPE --multicontainer-config-file FILE

# Copy the result of the following command into a browser to see the static HTML site.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site"
# </FullScript>

# See app-service/scripts/cli-linux-docker-aspnetcore.md for additional steps

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
