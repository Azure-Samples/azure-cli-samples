#!/bin/bash

# Create a resource group
az group create \
--name myresource \
--location westus

# Create a MySQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure
# Substitute the <server_admin_password> with your own value
az mysql server create \
--name mysqlserver4demo \
--resource-group myresource \
--location westus \
--admin-user myadmin \
--admin-password <server_admin_password> \
--performance-tier Basic \
--compute-units 50

# List the configuration options for review
az mysql server configuration list \
--resource-group myresource \
--server mysqlserver4demo

# Turn on slow query log
az mysql server configuration set \
--name slow_query_log \
--resource-group myresource \
--server mysqlserver4demo \
--value ON

# Set long query time to 10 sec
az mysql server configuration set \
--name long_query_time \
--resource-group myresource \
--server mysqlserver4demo \
--value 10

# Turn off the logging of slow admin statement
az mysql server configuration set \
--name log_slow_admin_statements \
--resource-group myresource \
--server mysqlserver4demo \
--value OFF

# List the available log files and direct to a text file
az mysql server-logs list \
--resource-group myresource \
--server mysqlserver4demo > log_files_list.txt

# Download logs to your environment
# Use "cat log_files_list.txt" to find the server log file name
# Substitute the <log_file_name> with your server log file name
az mysql server-logs download \
--name <log_file_name> \
--resource-group myresource \
--server mysqlserver4demo
