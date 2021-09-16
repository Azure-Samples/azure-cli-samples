#!/bin/bash

RESOURCE_GROUP="myresourcegroup"
SOURCE_SERVER="mydemoserver" # Enter source server name.
NEW_SERVER="mydemoserver-restored" # Enter new server name.

# Delete Source Server and New Server
az mysql flexible-server delete \
--resource-group $RESOURCE_GROUP 
--name $SOURCE_SERVER

az mysql flexible-server delete \
--resource-group $RESOURCE_GROUP 
--name $NEW_SERVER

# Optional : Delete resource group
az group delete --name $RESOURCE_GROUP