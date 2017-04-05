#/bin/bash

# Variables
resourceGroupName="myResourceGroup$RANDOM"
cacheName="myCache$RANDOM"
location="eastus"

# Create a Resource Group 
az group create --name $resourceGroupName --location $location

# Create a Redis Cache
az redis create --name $cacheName --resource-group $resourceGroupName --location $location --sku-capacity 0 --sku-family C --sku-name Basic

