#!/bin/bash

# The logical server name has to be unique in the system
servername=server-$RANDOM
# The ip address range that you want to allow to access your DB
startip=0.0.0.0
endip=255.255.255.255

# Login to Azure
# az login

# Create a resource group
az group create -n SampleResourceGroup -l northcentralus

# Create a logical server in the resource group
az sql server create -n $servername -g SampleResourceGroup -l northcentralus \
	--administrator-login ServerAdmin --administrator-login-password ASecureP@ssw0rd

# Configure a firewall rule for the server
az sql server firewall create -g SampleResourceGroup --server-name $servername \
	-n AllowYourIp --start-ip-address $startip --end-ip-address $endip

# Create a database in the server
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --requested-service-objective-name S0

# Cleanup the resource group and all the resouces in it
# az group delete -n SampleResourceGroup
