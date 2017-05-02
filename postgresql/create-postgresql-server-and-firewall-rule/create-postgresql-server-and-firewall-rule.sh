#!/bin/bash
# Set an admin login and password for your server
adminlogin=ServerAdmin
password=ChangeYourAdminPassword1
# The server name has to be unique in the system
servername=server-$RANDOM
# The ip address range that you want to allow to access your server
startip=0.0.0.0
endip=255.255.255.255

# Create a resource group in the westus region
az group create \
--name myResourceGroup \
--location westus

# Create a PostgreSQL server in the resource group
az postgres server create \
--name $servername \
--resource-group myResourceGroup \
--location westus \
--admin-user $adminlogin \
--admin-password $password \
--performance-tier Standard \
--compute-units 100 \

# Configure a firewall rule for the server
az postgres server firewall-rule create \
--resource-group myResourceGroup \
--server $servername \
--name AllowIps \
--start-ip-address $startip \
--end-ip-address $endip

# Default database 'postgres' gets created on the server.