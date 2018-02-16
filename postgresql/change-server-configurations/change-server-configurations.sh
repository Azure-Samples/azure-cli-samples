#!/bin/bash

# Create a resource group
az group create \
--name myresourcegroup \
--location westus

# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
# Substitute the <server_admin_password> with your own value.
az postgres server create \
--name mydemoserver \
--resource-group myresourcegroup \
--location westus \
--admin-user myadmin \
--admin-password <server_admin_password> \
--sku-name GP_Gen4_2 \

# Display all available configurations with valid values of an Azure Database for PostgreSQL server
az postgres server configuration list \
--resource-group myresourcegroup \
--server-name mydemoserver

# Set value of **log_retention_days**
az postgres server configuration set \
--resource-group myresourcegroup \
--server-name mydemoserver \
--name log_retention_days \
--value 7

# Check the value of **log_retention_days**
az postgres server configuration show \
--resource-group myresourcegroup \
--server-name mydemoserver \
--name log_retention_days 