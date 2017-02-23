#!/bin/bash

# Set an admin login and password for your database
adminlogin=ServerAdmin
password=
# The logical server name has to be unique in the system
servername=server-$RANDOM
# The ip address range that you want to allow to access your DB
startip=0.0.0.0
endip=255.255.255.255

# Create a resource group
az group create -n SampleResourceGroup -l northcentralus

# Create a logical server in the resource group
az sql server create -n $servername -g SampleResourceGroup -l northcentralus \
	--administrator-login $adminlogin --administrator-login-password $password

# Configure a firewall rule for the server
az sql server firewall create -g SampleResourceGroup --server-name $servername \
	-n AllowYourIp --start-ip-address $startip --end-ip-address $endip

# Create a database in the server
az sql db create -g SampleResourceGroup -l northcentralus --server-name $servername \
	-n MySampleDatabase --requested-service-objective-name S0

