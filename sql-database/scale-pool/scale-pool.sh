#!/bin/bash

# the logical server name has to be unique in the system
servername=server-$RANDOM

# Login to Azure
# az login

# Create a resource group
az group create -n SampleResourceGroup -l northcentralus

# Create a server
az sql server create -n $servername -g SampleResourceGroup -l northcentralus \
	--administrator-login ServerAdmin --administrator-login-password ASecureP@ssw0rd

# Create a pool
az sql elastic-pools create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n samplepool --dtu 50 --database-dtu-max 20

# Create a database
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --elastic-pool-name samplepool

# Scale up to the pool to 100 eDTU
az sql elastic-pools update -g SampleResourceGroup --server-name $servername \
	-n samplepool --set dtu=100

# Cleanup
# az group delete -n SampleResourceGroup
