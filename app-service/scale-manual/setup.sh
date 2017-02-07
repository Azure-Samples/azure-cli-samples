#/bin/bash

random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')
resourceGroupName="myResourceGroup$random"
appName="AppServiceManualScale$random"
location="WestUS"

az group create --name $resourceGroupName --location $location
az appservice plan create --name AppServiceManualScalePlan --resource-group $resourceGroupName --location $location --sku B1
az appservice web create --name $appName --plan AppServiceManualScalePlan --resource-group $resourceGroupName

az appservice plan update --number-of-workers 2 --name AppServiceManualScalePlan --resource-group $resourceGroupName