#/bin/bash

# Variables
resourceGroupName="myResourceGroup"
cacheName="myCache"

# Retrieve the details for an Azure Redis Cache instance, including provisioning status
az redis show --name $cacheName --resource-group $resourceGroupName 