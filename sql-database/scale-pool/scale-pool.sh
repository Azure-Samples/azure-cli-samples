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

# Create a pool
az sql elastic-pools create -g myResourceGroup -l northcentralus --server-name $servername \
	-n samplepool --dtu 50 --database-dtu-max 20

# Create two database in the pool
az sql db create -g myResourceGroup -l northcentralus --server-name $servername \
	-n myFirstSampleDatabase --elastic-pool-name samplepool
az sql db create -g myResourceGroup -l northcentralus --server-name $servername \
	-n mySecondSampleDatabase --elastic-pool-name samplepool

# Scale up to the pool to 100 eDTU
az sql elastic-pools update -g myResourceGroup --server-name $servername \
	-n samplepool --set dtu=100
