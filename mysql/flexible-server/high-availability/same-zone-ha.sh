#!/bin/bash

# Configure Same-zone High Availability

# Set up variables
RESOURCE_GROUP="myresourcegroup" # Substitute with preferred resource group name
SERVER_NAME="mydemoserver" # Substitute with preferred name for MySQL Flexible Server. Name of a server maps to DNS name and is thus required to be globally unique in Azure.
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS= # Enter your IP Address for Public Access - https://whatismyipaddress.com

# 1. Create resource group
az group create \
--name $RESOURCE_GROUP \
--location $LOCATION

# 2. Enable Same-zone HA while creating a MySQL Flexible server in the resource group
# HA is not available for burstable tier

az mysql flexible-server create \
--name $SERVER_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--sku-name Standard_D2ds_v4 \
--tier GeneralPurpose \
--admin-user $ADMIN_USER \
--admin-password $PASSWORD \
--public-access $IP_ADDRESS \
--high-availability SameZone

# 3. Disable Same-zone HA

az mysql flexible-server update \
--resource-group $RESOURCE_GROUP \ 
--name $SERVER_NAME \
--high-availability Disabled 