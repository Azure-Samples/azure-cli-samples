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

# Restore a server from backup to a new server
az mysql server restore \
--name mysqlserver4demo-new \
--resource-group myresource \
--restore-point-in-time "2017-10-13T13:10:00Z" \
--source-server mysqlserver4demo