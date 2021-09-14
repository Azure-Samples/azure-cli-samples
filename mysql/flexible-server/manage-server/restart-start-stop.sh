#!/bin/bash

# Create a server, perform restart / start / stop operations

# Set up variables
RESOURCE_GROUP="myresourcegroup" # Substitute with preferred resource group name
SERVER_NAME="mydemoserver" # Substitute with preferred name for MySQL Flexible Server. Name of a server maps to DNS name and is thus required to be globally unique in Azure.
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS=# Enter your IP Address for Public Access - https://whatismyipaddress.com

# 1. Create a resource group
az group create \
--name $RESOURCE_GROUP \
--location $LOCATION

# 2. Create a MySQL Flexible server in the resource group

az mysql flexible-server create \
--name $SERVER_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--admin-user $ADMIN_USER \
--admin-password $PASSWORD \
--public-access $IP_ADDRESS

# 3. Stop the running server
az mysql flexible-server stop \
--resource-group $RESOURCE_GROUP \
--name $SERVER_NAME

# 4. Start the stopped server
az mysql flexible-server start \
--resource-group $RESOURCE_GROUP \
--name $SERVER_NAME

# 5. Restart the server
az mysql flexible-server restart \
--resource-group $RESOURCE_GROUP \
--name $SERVER_NAME