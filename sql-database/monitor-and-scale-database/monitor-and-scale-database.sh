#!/bin/bash

# Set an admin login and password for your database
adminlogin=ServerAdmin
password=
# the logical server name has to be unique in the system
servername=server-$RANDOM

# Create a resource group
az group create -n SampleResourceGroup -l northcentralus

# Create a server
az sql server create -n $servername -g SampleResourceGroup -l northcentralus \
	--administrator-login $adminlogin --administrator-login-password $password

# Create a database
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --requested-service-objective-name S0

# Monitor database size
az sql db show-usage -n MySampleDatabase -g SampleResourceGroup --server-name $servername

# Scale up database to S1 performance level (create command executes update if DB already exists)
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --requested-service-objective-name S1
