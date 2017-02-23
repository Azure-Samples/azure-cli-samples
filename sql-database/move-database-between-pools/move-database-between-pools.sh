#!/bin/bash

# Set an admin login and password for your database
adminlogin=ServerAdmin
password=ChangeYourAdminPassword1
# The logical server name has to be unique in the system
servername=server-$RANDOM

# Create a resource group
az group create -n MyResourceGroup -l northcentralus

# Create a logical server in the resource group
az sql server create -n $servername -g MyResourceGroup -l northcentralus \
	--administrator-login $adminlogin --administrator-login-password $password

# Create two pools in the logical server
az sql elastic-pools create -g MyResourceGroup -l northcentralus --server-name $servername \
	-n MyFirstPool --dtu 50 --database-dtu-max 20
az sql elastic-pools create -g MyResourceGroup -l northcentralus --server-name $servername \
	-n MySecondPool --dtu 50 --database-dtu-max 50

# Create a database in the first pool
az sql db create -g MyResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --elastic-pool-name MyFirstPool

# Move the database to the second pool - create command updates the db if it exists
az sql db create -g MyResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --elastic-pool-name MySecondPool

# Move the database to standalone S1 performance level
az sql db create -g MyResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --requested-service-objective-name S1
