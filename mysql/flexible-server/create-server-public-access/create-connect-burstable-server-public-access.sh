#!/bin/bash

# Create an Azure Database for MySQL - Flexible Server Burstable B1ms instance
# and configure Public Access connectivity method

# Set up variables
RESOURCE_GROUP="myresourcegroup" 
SERVER_NAME="mydemoserver" # Substitute with preferred name for your MySQL Flexible Server. 
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password
IP_ADDRESS=  # Enter your IP Address for Public Access - https://whatismyipaddress.com

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

# Optional: Add firewall rule to connect from all Azure services
# To allow other IP addresses, change start-ip-address and end-ip-address

az mysql flexible-server firewall-rule create \
--name $SERVER_NAME \
--resource-group $RESOURCE_GROUP \
--rule-name AllowAzureIPs \
--start-ip-address 0.0.0.0 \
--end-ip-address 0.0.0.0

# 3. Connect to server in interactive mode
az mysql flexible-server connect \
--name $SERVER_NAME \
--admin-user $ADMIN_USER \
--admin-password $PASSWORD \
--interactive