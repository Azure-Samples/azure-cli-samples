#!/bin/bash

# Set an admin login and password for your database
adminlogin=ServerAdmin
password=ChangeYourAdminPassword1
# the logical server name has to be unique in the system
servername=server-$RANDOM

# Create a resource group
az group create -n myResourceGroup -l northcentralus

# Create a server
az sql server create -n $servername -g myResourceGroup -l northcentralus \
	--administrator-login $adminlogin --administrator-login-password $password

# Create a database
az sql db create -g myResourceGroup -l northcentralus --server-name $servername \
	-n mySampleDatabase --requested-service-objective-name S0

# Monitor database size
az sql db show-usage -n mySampleDatabase -g myResourceGroup --server-name $servername

# Scale up database to S1 performance level (create command executes update if DB already exists)
az sql db create -g myResourceGroup -l northcentralus --server-name $servername \
	-n mySampleDatabase --requested-service-objective-name S1
