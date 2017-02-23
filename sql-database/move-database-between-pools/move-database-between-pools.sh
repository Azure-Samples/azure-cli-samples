#!/bin/bash

# Set an admin login and password for your database
adminlogin=ServerAdmin
password=ChangeYourAdminPassword1
# The logical server name has to be unique in the system
servername=server-$RANDOM

# Create a resource group
az group create -n myResourceGroup -l northcentralus

# Create a logical server in the resource group
az sql server create -n $servername -g myResourceGroup -l northcentralus \
	--administrator-login $adminlogin --administrator-login-password $password

# Create two pools in the logical server
az sql elastic-pools create -g myResourceGroup -l northcentralus --server-name $servername \
	-n myFirstPool --dtu 50 --database-dtu-max 20
az sql elastic-pools create -g myResourceGroup -l northcentralus --server-name $servername \
	-n MySecondPool --dtu 50 --database-dtu-max 50

# Create a database in the first pool
az sql db create -g myResourceGroup -l northcentralus --server-name $servername \
	-n mySampleDatabase --elastic-pool-name myFirstPool

# Move the database to the second pool - create command updates the db if it exists
az sql db create -g myResourceGroup -l northcentralus --server-name $servername \
	-n mySampleDatabase --elastic-pool-name mySecondPool

# Move the database to standalone S1 performance level
az sql db create -g myResourceGroup -l northcentralus --server-name $servername \
	-n mySampleDatabase --requested-service-objective-name S1
