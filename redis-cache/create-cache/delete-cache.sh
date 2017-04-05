#/bin/bash

# Variables
resourceGroupName="myResourceGroup"
cacheName="myCache"

# Delete a Redis Cache
az redis delete --name $cacheName --resource-group $resourceGroupName
