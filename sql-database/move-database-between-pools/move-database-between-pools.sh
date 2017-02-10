#!/bin/bash

# The logical server name has to be unique in the system
servername=server-$RANDOM

# Login to Azure
# az login

# Create a resource group
az group create -n SampleResourceGroup -l northcentralus

# Create a logical server in the resource group
az sql server create -n $servername -g SampleResourceGroup -l northcentralus \
	--administrator-login ServerAdmin --administrator-login-password ASecureP@ssw0rd

# Create two pools in the logical server
az sql elastic-pools create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MyFirstPool --dtu 50 --database-dtu-max 20
az sql elastic-pools create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySecondPool --dtu 50 --database-dtu-max 20

# Create a database in the first pool
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --elastic-pool-name MyFirstPool

# Move the database to the second pool - create command updates the db if it exists
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --elastic-pool-name MySecondPool

# Move the database to standalone S1 performance level
az sql db update -g SampleResourceGroup --server-name $servername \
	-n MySampleDatabase --set requestedServiceObjectiveId=1b1ebd4d-d903-4baa-97f9-4ea675f5e928

# Cleanup the resource group and all resources in it
# az group delete -n SampleResourceGroup
