#!/bin/bash

# Download the Azure CLI extension 
az extension add --name rdbms

# Create a resource group
az group create \
--name myresourcegroup \
--location westus

# Create a MySQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
# Substitute the <server_admin_password> with your own value.
az mysql server create \
--name mydemoserver \
--resource-group myresourcegroup \
--location westus \
--admin-user myadmin \
--admin-password <server_admin_password> \
--sku-name GP_Gen4_2 \

# Display all available configurations with valid values of an Azure Database for MySQL server
az mysql server configuration list \
--resource-group myresourcegroup \
--server-name mydemoserver

# Set value of *innodb_lock_wait_timeout*
az mysql server configuration set \
--resource-group myresourcegroup \
--server-name mydemoserver \
--name innodb_lock_wait_timeout \
--value 120

# Check the value of *innodb_lock_wait_timeout*
az mysql server configuration show \
--resource-group myresourcegroup \
--server-name mydemoserver \
--name innodb_lock_wait_timeout