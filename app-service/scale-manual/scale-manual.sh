#/bin/bash

# Variables
appName="AppServiceManualScale$random"
location="WestUS"

# Create a Resource Group
az group create --name myResourceGroup --location $location

# Create App Service Plans
az appservice plan create --name AppServiceManualScalePlan --resource-group myResourceGroup --location $location --sku B1

# Add a Web App
az webapp create --name $appName --plan AppServiceManualScalePlan --resource-group myResourceGroup

# Scale Web App to 2 Workers
az appservice plan update --number-of-workers 2 --name AppServiceManualScalePlan --resource-group myResourceGroup