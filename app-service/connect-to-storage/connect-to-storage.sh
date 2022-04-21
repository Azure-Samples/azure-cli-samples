#/bin/bash

# <FullScript>
# set -e # exit if error
# Create an App Service app and deploy files with FTP
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="connect-to-storage"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"
storage="webappstore$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service Plan
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup \
--location "$location"

# Create a Web App
echo "Creating $webapp"
az webapp create --name $webapp --plan $appServicePlan --resource-group $resourceGroup 

# Create a storage account
echo "Creating $storage"
az storage account create --name $storage --resource-group $resourceGroup \
--location "$location" --sku Standard_LRS

# Retreive the storage account connection string 
connstr=$(az storage account show-connection-string --name $storage --resource-group $resourceGroup \
--query connectionString --output tsv)

# Assign the connection string to an App Setting in the Web App
az webapp config appsettings set --name $webapp --resource-group $resourceGroup \
--settings "STORAGE_CONNSTR=$connstr"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
