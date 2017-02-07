#/bin/bash

random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')
resourceGroupName="myResourceGroup$random"
appName="webappwithstorage$random"
storageName="webappstorage$random"
location="WestUS"

az group create --name $resourceGroupName --location $location
az appservice plan create --name WebAppWithStoragePlan --resource-group $resourceGroupName --location $location
az appservice web create --name $appName --plan WebAppWithStoragePlan --resource-group $resourceGroupName 

az storage account create --name $storageName --resource-group $resourceGroupName --location $location --sku Standard_LRS
connstr=$(az storage account show-connection-string --name $storageName --resource-group $resourceGroupName --query connectionString --output tsv)

az appservice web config appsettings update --settings "STORAGE_CONNSTR=$connstr" --name $appName --resource-group $resourceGroupName