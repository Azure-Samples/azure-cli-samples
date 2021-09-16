#!/bin/bash

RESOURCE_GROUP="myresourcegroup" 
SERVER_NAME="mydemoserver" # Enter your server name

# Delete MySQL Flexible Server
az mysql flexible-server delete \
--resource-group $RESOURCE_GROUP 
--name $SERVER_NAME

# Optional : Delete resource group

az group delete --name $RESOURCE_GROUP