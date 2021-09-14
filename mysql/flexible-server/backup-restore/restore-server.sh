#!/bin/bash

# Perform point-in-time-restore of a source server to a new server

# Set up variables
RESOURCE_GROUP="myresourcegroup" # Substitute with preferred resource group name
SOURCE_SERVER="mydemoserver" # Substitute with preferred name for MySQL Flexible Server. Name of a server maps to DNS name and is thus required to be globally unique in Azure.
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS= # Enter your IP Address for Public Access - https://whatismyipaddress.com
NEW_SERVER="mydemoserver-restored" # Substitute with preferred name for new Flexible Server.

# 1. Create a resource group
az group create \
--name $RESOURCE_GROUP \
--location $LOCATION

# 2. Create a MySQL Flexible server in the resource group

az mysql flexible-server create \
--name $SOURCE_SERVER \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--admin-user $ADMIN_USER \
--admin-password $PASSWORD \
--public-access $IP_ADDRESS


# 3. Restore source server to a specific point-in-time as a new server 'mydemoserver-restored'.
# Substitute the 'restore-time' with your desired value in ISO8601 format

az mysql flexible-server restore \
--name $NEW_SERVER \
--resource-group $RESOURCE_GROUP \
--restore-time "2021-07-09T13:10:00Z" \
--source-server $SOURCE_SERVER

# 4. Check server parameters and networking options on new server before use

az mysql flexible-server show \
--resource-group $RESOURCE_GROUP \
--name $NEW_SERVER