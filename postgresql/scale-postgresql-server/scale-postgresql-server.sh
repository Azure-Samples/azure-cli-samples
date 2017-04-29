#!/bin/bash
# Set an admin login and password for your database
adminlogin=ServerAdmin
password=ChangeYourAdminPassword1

# the logical server name has to be unique in the system
servername=server-$RANDOM

# Create a resource group
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

# Monitor usage metrics

# Scale up the server to provision more Compute Units
az postgres server update \
--resource-group myResourceGroup \
--name $servername \
--compute-units 400