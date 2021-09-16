#!/bin/bash

# Create and manage Flexible Server Read Replicas

# Set up variables
RESOURCE_GROUP="myresourcegroup" 
SOURCE_SERVER="mydemoserver" # Substitute with preferred name for MySQL Flexible Server. 
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS= # Enter your IP Address for Public Access - https://whatismyipaddress.com
REPLICA_NAME="mydemoserver-replica" # Substitute with preferred name for the replica server. 

# 1. Create resource group
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
--public-access $IP_ADDRESS \
--sku-name Standard_D2ds_v4 \
--tier GeneralPurpose \
--storage-size 64

# 3. Create Replica Server
az mysql flexible-server replica create \
--replica-name $REPLICA_NAME \
--source-server $SOURCE_SERVER \
--resource-group $RESOURCE_GROUP

# 4. List all read replicas for the source server

az mysql flexible-server replica list \
--resource-group $RESOURCE_GROUP \
--name $SOURCE_SERVER 

# 5. Stop replication to a read replica and make it a read/write server.

az mysql flexible-server replica stop-replication \
--resource-group $RESOURCE_GROUP \
--name $REPLICA_NAME