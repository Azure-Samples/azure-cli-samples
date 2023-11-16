#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Bind a custom TLS/SSL certificate to an App Service app
#
# This sample script creates an app in App Service with its
# related resources, then binds the TLS/SSL certificate of
# a custom domain name to it. For this sample, you need:
#
# Access to your domain registrar's DNS configuration page.
# A valid .PFX file and its password for the TLS/SSL
# certificate you want to upload and bind.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="configure-ssl-certificate-webapp-only.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in Basic tier (minimum required by custom domains).
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku B1

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

# Copy the result of the following command into a browser to see the static HTML site.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site"
# </FullScript>

# See app-service/scripts/cli-configure-ssl-certificate.md for additional steps

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
