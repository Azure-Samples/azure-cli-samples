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

# Configure a firewall rule for the server
# The ip address range that you want to allow to access your server
az mariadb server firewall-rule create \
--resource-group myresourcegroup \
--server mydemoserver \
--name AllowIps \
--start-ip-address 0.0.0.0 \
--end-ip-address 255.255.255.255
