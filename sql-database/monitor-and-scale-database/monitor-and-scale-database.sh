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

# Create a database
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --requested-service-objective-name S0

# Monitor database size
az sql db show-usage -n MySampleDatabase -g SampleResourceGroup --server-name $servername

# Scale up to database to S1 performance level
az sql db update -g SampleResourceGroup --server-name $servername \
	-n MySampleDatabase --set requestedServiceObjectiveId=1b1ebd4d-d903-4baa-97f9-4ea675f5e928

# Cleanup
# az group delete -n SampleResourceGroup
