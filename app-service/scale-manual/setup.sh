#/bin/bash

# Ensures unique id
random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')

# Variables
resourceGroupName="myResourceGroup$random"
appName="AppServiceManualScale$random"
location="WestUS"

# Create a Resource Group
az group create --name $resourceGroupName --location $location1

# Create App Service Plans
az appservice plan create --name AppServiceManualScalePlan --resource-group $resourceGroupName --location $location --sku B1

# Add a Web App
az appservice web create --name $appName --plan AppServiceManualScalePlan --resource-group $resourceGroupName

# Scale Web App to 2 Workers
az appservice plan update --number-of-workers 2 --name AppServiceManualScalePlan --resource-group $resourceGroupName