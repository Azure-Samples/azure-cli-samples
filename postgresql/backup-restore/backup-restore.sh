#!/bin/bash

# Create a resource group
az group create \
--name myresourcegroup \
--location westus

# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
# Substitute the <server_admin_password> with your own value.
az postgres server create \
--name mypgserver-20170401 \
--resource-group myresourcegroup \
--location westus \
--admin-user mylogin \
--admin-password <server_admin_password> \
--performance-tier Basic \
--compute-units 50

# Restore a server from backup to a new server
az postgres server restore \
--name mypgserver-restored \
--resource-group myresourcegroup \
--restore-point-in-time "2017-10-13T13:10:00Z" \
--source-server mypgserver-20170401