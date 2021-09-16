#!/bin/bash

# Configure Zone-redundant High Availability

# Set up variables
RESOURCE_GROUP="myresourcegroup" 
SERVER_NAME="mydemoserver" # Substitute with preferred name for MySQL Flexible Server. 
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS= # Enter your IP Address for Public Access - https://whatismyipaddress.com

PRIMARY_ZONE=1
STANDBY_ZONE=2

# 1. Create resource group
az group create \
--name $RESOURCE_GROUP \
--location $LOCATION

# 2. Enable Zone-redundant HA while creating a MySQL Flexible server in the resource group
# HA is not available for burstable tier
# zone and standby-zone parameters are optional

az mysql flexible-server create \
--name $SERVER_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--sku-name Standard_D2ds_v4 \
--tier GeneralPurpose \
--admin-user $ADMIN_USER \
--admin-password $PASSWORD \
--public-access $IP_ADDRESS \
--high-availability ZoneRedundant \
--zone $PRIMARY_ZONE \
--standby-zone $STANDBY_ZONE

# 3. Disable Zone-redundant HA

az mysql flexible-server update \
--resource-group $RESOURCE_GROUP \ 
--name $SERVER_NAME \
--high-availability Disabled