#!/bin/bash

# Configure slow query logs on Azure Database for MySQL Flexible Server

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

# 3. Enable slow query logs

az mysql flexible-server parameter set \
--name slow_query_log \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--value ON

# 4. Set long_query_time time to 15 sec
# This setting will log all queries executing for more than 15 sec. Please adjust this threshold based on your definition for slow queries

az mysql flexible-server parameter set \
--name long_query_time \
--resource-group $RESOURCE_GROUP \
--server $SERVER_NAME \
--value 15

# 5. Allow slow administrative statements (ex. ALTER_TABLE, ANALYZE_TABLE) to be logged.

az mysql flexible-server parameter set \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--name log_slow_admin_statements \
--value ON