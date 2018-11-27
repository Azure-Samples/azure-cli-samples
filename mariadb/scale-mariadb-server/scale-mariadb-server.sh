#!/bin/bash

# Create a resource group
az group create \
--name myresourcegroup \
--location westus

# Create a MariaDB server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
# Substitute the <server_admin_password> with your own value.
az mariadb server create \
--name mydemoserver \
--resource-group myresourcegroup \
--location westus \
--admin-user myadmin \
--admin-password <server_admin_password> \
--sku-name GP_Gen5_2 \

# Monitor usage metrics - CPU
az monitor metrics list \
--resource "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myresourcegroup/providers/Microsoft.DBforMariaDB/servers/mydemoserver" \
--metric cpu_percent \
--interval PT1M

# Monitor usage metrics - Storage
az monitor metrics list \
--resource-id "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myresourcegroup/providers/Microsoft.DBforMariaDB/servers/mydemoserver" \
--metric storage_used \
--interval PT1M

# Scale up the server to provision more vCores within the same Tier
az mariadb server update \
--resource-group myresourcegroup \
--name mydemoserver \
--sku-name GP_Gen5_4

# Scale up the server to provision a storage size of 7GB
az mariadb server update \
--resource-group myresourcegroup \
--name mydemoserver \
--storage-size 7168