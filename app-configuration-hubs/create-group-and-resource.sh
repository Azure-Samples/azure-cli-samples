#!/bin/bash

appConfigName=myTestAppConfigHub
#resource name must be lowercase
myAppConfigHubName=${appConfigName,,}
myResourceGroupName=$appConfigName"Group"

# Create resource group 
az group create --name $myResourceGroupName --location eastus

# Create the Azure AppConfig Service resource and query the hostName
appConfigHostname=$(az appconfig create \
  --name $myAppConfigHubName \
  --resource-group $myResourceGroupName \
  --query hostName \
  -o tsv)
  
# Get the AppConfig primary key 
appConfigPrimaryKey=$(az appconfig key list --name $myAppConfigHubName \
  --resource-group $myResourceGroupName --query primaryKey -o tsv)

# Form the connection string for use in your application
connstring="Endpoint=https://$appConfigHostname;AccessKey=$appConfigPrimaryKey;"
echo "$connstring"
