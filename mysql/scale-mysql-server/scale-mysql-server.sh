#!/bin/bash

# Set up variables
RESOURCE_GROUP="myresourcegroup" ;
SERVER_NAME="mydemoserver-$RANDOM"
PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12) ; echo password $PASSWORD
LOCATION="westus"
ADMIN_USER="myadmin"
SUBSCRIPTION_ID="" # enter your subscription ID

# Create a resource group
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Create a MySQL server in the resource group
az mysql server create \
    --name $SERVER_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --admin-user $ADMIN_USER \
    --admin-password $PASSWORD \
    --sku-name GP_Gen5_2

# Monitor usage metrics - CPU
az monitor metrics list \
    --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DBforMySQL/servers/$SERVER_NAME" \
    --metric cpu_percent \
    --interval PT1M

# Monitor usage metrics - Storage
az monitor metrics list \
    --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DBforMySQL/servers/$SERVER_NAME" \
    --metric storage_used \
    --interval PT1M

# Scale up the server by provisionining more vCores within the same tier
az mysql server update \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --sku-name GP_Gen5_4

# Scale down the server by provisioning fewer vCores within the same tier
az mysql server update \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --sku-name GP_Gen5_2

# Scale up the server to provision a storage size of 7GB
# Storage size cannot be reduced
az mysql server update \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --storage-size 7168