#!/bin/bash

# Download the Azure CLI extension 
az extension add --name rdbms

# Create a resource group
az group create \
--name myresourcegroup  \
--location westus

# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure
# Substitute the <server_admin_password> with your own value
az postgres server create \
--name mydemoserver \
--resource-group myresourcegroup \
--location westus \
--admin-user myadmin \
--admin-password <server_admin_password> \
--sku-name GP_Gen4_2 \

# List the configuration options for review
az postgres server configuration list \
--resource-group myresourcegroup  \
--server mydemoserver

# Turn on statement level log
az postgres server configuration set \
--name log_statement \
--resource-group myresourcegroup \
--server mydemoserver \
--value all

# Set log_min_duration_statement time to 10 sec
az postgres server configuration set \
--name log_min_duration_statement \
--resource-group myresourcegroup \
--server mydemoserver \
--value 10000

# List the available log files and direct to a text file
az postgres server-logs list \
--resource-group myresourcegroup \
--server mydemoserver > log_files_list.txt

# Download log file from Azure 
# Review log_files_list.txt to find the server log file name for the desired timeframe
# Substitute the <log_file_name> with your server log file name
# Creates the postgresql-<date>_000000.log file in the current command line path
az postgres server-logs download \
--name <log_file_name> \
--resource-group myresourcegroup \
--server mydemoserver