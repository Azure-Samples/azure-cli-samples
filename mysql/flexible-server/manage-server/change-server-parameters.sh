#!/bin/bash

# Change server parameters for Azure Database for MySQL - Flexible Server

# Set up variables
RESOURCE_GROUP="myresourcegroup" # Substitute with preferred resource group name
SERVER_NAME="mydemoserver" # Substitute with preferred name for MySQL Flexible Server. Name of a server maps to DNS name and is thus required to be globally unique in Azure.
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS= # Enter your IP Address for Public Access - https://whatismyipaddress.com

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

# 3. List all Flexible Server parameters with their values and parameter descriptions
az mysql flexible-server parameter list \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME

# 4. Set and check parameter values

# Set value of max_connections parameter
az mysql flexible-server parameter set \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--name max_connections \
--value 250

# Check value of max_connections paramater

az mysql flexible-server parameter show \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--name max_connections

# Set value of max_connections parameter back to default

az mysql flexible-server parameter set \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--name max_connections 

# Set global level time zone
az mysql flexible-server parameter set \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--name time_zone \
--value "+02:00"

# Check global level time zone

az mysql flexible-server parameter show \
--resource-group $RESOURCE_GROUP \
--server-name $SERVER_NAME \
--name time_zone