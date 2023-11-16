#!/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Create an App Service app and deploy files with FTP
#
# This sample script creates an app in App Service with its related resources, 
# and then deploys a static HTML page using FTP. For FTP upload, the script uses
# cURL as an example. You can use whatever FTP tool to upload your files.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="deploy-ftp.sh"
warurl="https://raw.githubusercontent.com/Azure-Samples/html-docs-hello-world/master/index.html"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Download sample static HTML page
curl $warurl --output index.html

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service plan in `FREE` tier.
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku FREE

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

# Get FTP publishing profile and query for publish URL and credentials
creds=($(az webapp deployment list-publishing-profiles --name $webapp --resource-group $resourceGroup \
--query "[?contains(publishMethod, 'FTP')].[publishUrl,userName,userPWD]" --output tsv))

# Use cURL to perform FTP upload. You can use any FTP tool to do this instead. 
curl -T index.html -u ${creds[1]}:${creds[2]} ${creds[0]}/

# Copy the result of the following command into a browser to see the static HTML site.
site="http://$webapp.azurewebsites.net"
echo $site
curl "$site"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
