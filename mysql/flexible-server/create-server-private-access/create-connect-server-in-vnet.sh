#!/bin/bash

# Create an Azure Database for MySQL - Flexible Server (General Purpose SKU) in VNET - with Private Access connectivity method
# Connect to the server from a VM within the VNET.

RESOURCE_GROUP="myresourcegroup" # Substitute with preferred resource group name
SERVER_NAME="mydemoserver" # Substitute with preferred name for your MySQL Flexible Server. Name of a server maps to DNS name and is thus required to be globally unique in Azure.
LOCATION="westus" 
ADMIN_USER="mysqladmin" 
PASSWORD="" # Enter your server admin password

# 1. Create a resource group
az group create \
--name $RESOURCE_GROUP \
--location $LOCATION

# OPTIONAL : View all SKUs for Flexible Server
az mysql flexible-server list-skus --location $LOCATION

# 2. Create a MySQL Flexible server in the resource group

az mysql flexible-server create \
--name $SERVER_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--sku-name Standard_D2ds_v4 \
--tier GeneralPurpose \
--storage-size 64 \
--storage-auto-grow Enabled \
--admin-user $ADMIN_USER \
--admin-password $PASSWORD \
--vnet MyVnet \
--address-prefixes 155.5.0.0/24 \
--subnet mysql-subnet \
--subnet-prefixes 155.5.0.0/28 

# 3. Create a VM within the VNET to connect to MySQL Flex Server
    # a. Create a subnet within the VNET
    # b. Create VM within the created subnet

az network vnet subnet create \
--resource-group $RESOURCE_GROUP \
--vnet-name MyVnet \
--name vm-subnet \
--address-prefixes 155.5.0.48/28

az vm create \
--resource-group $RESOURCE_GROUP \
--name mydemoVM \
--location $LOCATION \
--image UbuntuLTS \
--admin-username azureuser \
--generate-ssh-keys \
--vnet-name MyVnet \
--subnet vm-subnet

# 4. Open port 80 for web traffic

az vm open-port --port 80 \
--resource-group $RESOURCE_GROUP \
--name mydemoVM

# 5. SSH into the VM
publicIp=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name mydemoVM --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)
ssh azureuser@$publicIp 

# 6. Download MySQL tools and connect to the server!
# Substitute <server_name> and <admin_user> with your values

sudo apt-get update
sudo apt-get install mysql-client

wget --no-check-certificate https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem

mysql -h <server_name>.mysql.database.azure.com -u <admin_user> -p --ssl-mode=REQUIRED --ssl-ca=DigiCertGlobalRootCA.crt.pem