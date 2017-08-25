#!/bin/bash

# Create a resource group
az group create \
--name myresource \
--location westus

# Create a MySQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
# Substitute the <server_admin_password> with your own value.
az mysql server create \
--name mysqlserver4demo \
--resource-group myresource \
--location westus \
--admin-user myadmin \
--admin-password <server_admin_password> \
--performance-tier Basic \
--compute-units 50

# Display all available configurations with valid values of an Azure Database for MySQL server
az mysql server configuration list \
--resource-group myresource \
--server-name mysqlserver4demo

# Set value of *innodb_lock_wait_timeout*
az mysql server configuration set \
--resource-group myresource \
--server-name mysqlserver4demo \
--name innodb_lock_wait_timeout \
--value 120

# Check the value of *innodb_lock_wait_timeout*
az mysql server configuration show \
--resource-group myresource \
--server-name mysqlserver4demo \
--name innodb_lock_wait_timeout