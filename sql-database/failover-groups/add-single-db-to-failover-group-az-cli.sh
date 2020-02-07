#!/bin/bash

subscriptionID=<subscriptionId>
resourceGroupName=myResourceGroup-$RANDOM
location=SouthCentralUS
adminLogin=azureuser
password="PWD27!"+`openssl rand -base64 18`
serverName=mysqlserver-$RANDOM
databaseName=mySampleDatabase
drLocation=NorthEurope
drServerName=mysqlsecondary-$RANDOM
failoverGroupName=failovergrouptutorial-$RANDOM

# The ip address range that you want to allow access to your DB. 
# Leaving at 0.0.0.0 will prevent outside-of-azure connections
startip=0.0.0.0
endip=0.0.0.0

# print out randomized variables
echo Resource group name is $resourceGroupName
echo Passowrd is $password
echo Servername is $serverName
echo DR Server name $drServerName
echo Failover group name $failoverGroupName

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create a resource group
echo "Creating resource group..."
az group create \
   --name $resourceGroupName \
   --location $location \
   --tags Owner[=SQLDB-Samples]

# create a logical server in the resource group
echo "Creating primary logical server..."
az sql server create \
   --name $serverName \
   --resource-group $resourceGroupName \
   --location $location  \
   --admin-user $adminLogin \
   --admin-password $password

# configure a firewall rule for the server
echo "Configuring firewall..."
az sql server firewall-rule create \
   --resource-group $resourceGroupName \
   --server $serverName \
   -n AllowYourIp \
   --start-ip-address $startip \
   --end-ip-address $endip

# create a gen5 2vCore database in the server 
echo "Creating a gen5 2 vCore database..."
az sql db create \
   --resource-group $resourceGroupName \
   --server $serverName \
   --name $databaseName \
   --sample-name AdventureWorksLT \
   --edition GeneralPurpose \
   --family Gen5 \
   --capacity 2

# create a secondary server in the failover region
echo "Creating a secondary logical server in the DR region..."
az sql server create \
   --name $drServerName \
   --resource-group $resourceGroupName \
   --location $drLocation  \
   --admin-user $adminLogin\
   --admin-password $password

# create a failover group between the servers and add the database
echo "Creating a failover group between the two servers..."
az sql failover-group create \
   --name $failoverGroupName  \
   --partner-server $drServerName \
   --resource-group $resourceGroupName \
   --server $serverName \
   --add-db $databaseName
   --failover-policy Automatic

# verify which server is secondary
echo "Verifying which server is in the secondary role..."
az sql failover-group list \
   --server $serverName \
   --resource-group $resourceGroupName

# failover to the secondary server
echo "Failing over group to the secondary server..."
az sql failover-group set-primary \
   --name $failoverGroupName \
   --resource-group $resourceGroupName \
   --server $drServerName
echo "Successfully failed failover group over to" $drServerName

# revert failover group back to the primary server
echo "Failing over group back to the primary server..."
az sql failover-group set-primary \
   --name $failoverGroupName \
   --resource-group $resourceGroupName \
   --server $serverName
echo "Successfully failed failover group back to" $serverName

# clean up resources by removing the resource group
# echo "Cleaning up resources by removing the resource group..."
# az group delete --name $resourceGroupName 
# echo "Successfully removed resource group" $resourceGroupName