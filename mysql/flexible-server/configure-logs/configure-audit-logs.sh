#!/bin/bash

# Configure audit logs on Azure Database for MySQL Flexible Server

# Set up variables
RESOURCE_GROUP="myresourcegroup" 
SERVER_NAME="mydemoserver" # Substitute with preferred name for MySQL Flexible Server.
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS= # Enter your IP Address for Public Access - https://whatismyipaddress.com

# 1. Create resource group
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

# 3. Enable audit logs

az mysql flexible-server parameter set \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--name audit_log_enabled \
--value ON