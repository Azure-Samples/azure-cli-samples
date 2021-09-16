#!/bin/bash

# Monitor your Flexible Server and scale Compute, Storage and IOPS

# Set up variables
SUBSCRIPTION_ID="" # Enter your subscription ID
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

# 3. Monitor CPU percent, storage usage and IO percent

# Monitor CPU Usage metric
az monitor metrics list \
    --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DBforMySQL/flexibleservers/$SERVER_NAME" \
    --metric cpu_percent \
    --interval PT1M

# Monitor Storage usage metric
az monitor metrics list \
    --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DBforMySQL/flexibleservers/$SERVER_NAME" \
    --metric storage_used \
    --interval PT1M

# Monitor IO Percent
az monitor metrics list \
    --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DBforMySQL/flexibleservers/$SERVER_NAME" \
    --metric io_consumption_percent \
    --interval PT1M

# 4. Scale up and down

# Scale up the server by provisionining to higher tier from Burstable to General purpose 4vcore
az mysql flexible-server update \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --sku-name Standard_D4ds_v4 \
    --tier GeneralPurpose 

# Scale down to by provisioning to General purpose 2vcore within the same tier
az mysql flexible-server update \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --sku-name Standard_D2ds_v4

# Scale up the server to provision a storage size of 64GB. Note storage size cannot be reduced.
az mysql flexible-server update \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --storage-size 64

# Scale IOPS
az mysql flexible-server update \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --iops 550
