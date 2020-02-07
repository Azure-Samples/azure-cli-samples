#!/bin/bash

$subscriptionId = '<subscriptionId>'
$randomIdentifier = $RANDOM
$resourceGroupName = "myResourceGroup-$randomIdentifier"
$location = "East US"
$adminLogin = "azureuser"
$password = "PWD27!"+(New-Guid).Guid
$serverName = "mysqlserver-$randomIdentifier"
$poolName = "myElasticPool"
$databaseName = "mySampleDatabase"
$drLocation = "West US"
$drServerName = "mysqlsecondary-$randomIdentifier"
$failoverGroupName = "failovergrouptutorial-$randomIdentifier"

# The ip address range that you want to allow to access your server 
# Leaving at 0.0.0.0 will prevent outside-of-azure connections
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# show randomized variables
echo "Resource group name is" $resourceGroupName 
echo "Password is" $password  
echo "Server name is" $serverName 
echo "DR Server name is" $drServerName 
echo "Failover group name is" $failoverGroupName

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create a resource group
echo "Creating resource group..."
az group create \
   --name $resourceGroupName \
   --location $location \
   --tags Owner[=SQLDB-Samples]

# create a server in the resource group
echo "Creating server..."
az sql server create \
   --name $serverName \
   --resource-group $resourceGroupName \
   --location $location  \
   --admin-user $adminLogin \
   --admin-password $password

# create a server firewall rule that allows access from the specified IP range
echo "Configuring firewall for primary logical server..."
az sql server firewall-rule create --end-ip-address $endIp \
   --name "AllowedIPs" \
   --resource-group $resourceGroupName \
   --server $serverName \
   --start-ip-address $startIp 
echo "Firewall configured"

# create General Purpose Gen5 database with 2 vCore
echo "Creating a gen5 2 vCore database..."
az sql db create --name $databaseName \
   --resource-group $resourceGroupName \
   --server $serverName \
   --edition "GeneralPurpose" \
   --family Gen5 \
   --max-size 2 \
   --min-capacity 1 \
   --sample-name "AdventureWorksLT"

# create primary Gen5 elastic 2 vCore pool
echo "Creating elastic pool..."
az sql elastic-pool create --name $poolName \
   --resource-group $resourceGroupName \
   --server $serverName \
   --edition "GeneralPurpose" \
   --family Gen5 \
   --max-size 2

# add single db into elastic pool
echo "Adding database to elastic pool..."
az sql db update --elastic-pool $poolName \
   --name $databaseName \
   --resource-group $resourceGroupName \
   --server $serverName

# create a secondary server in the failover region
echo "Creating secondary server..."
az sql server create \
   --name $drServerName \
   --resource-group $resourceGroupName \
   --location $drLocation  \
   --admin-user $adminLogin \
   --admin-password $password

# create a server firewall rule that allows access from the specified IP range
echo "Configuring firewall for primary logical server..."
az sql server firewall-rule create --end-ip-address $endIp \
   --name "AllowedIPs" \
   --resource-group $resourceGroupName \
   --server $drServerName \
   --start-ip-address $startIp 
echo "Firewall configured"

# create secondary Gen5 elastic 2 vCore pool
echo "Creating secondary elastic pool..."
az sql elastic-pool create --name $poolName \
   --resource-group $resourceGroupName \
   --server $drServerName \
   --edition "GeneralPurpose" \
   --family Gen5 \
   --max-size 2

# create a failover group between the servers
echo "Creating failover group..." 
az sql failover-group create --name $failoverGroupName \
   --partner-server $drServerName \
   --resource-group $resourceGroupName \
   --server $serverName \
   --failover-policy Automatic \
   --grace-period 2
echo "Failover group created successfully."

# add elastic pool to the failover group
echo "Enumerating databases in elastic pool...." 
$databases = az sql elastic-pool list-dbs --name $poolName \
   --resource-group $resourceGroupName \
   --server $serverName 
echo "Adding databases to failover group..." 
az sql failover-group update --name $failoverGroupName \
   --add-db $databases \
   --resource-group $resourceGroupName \
   --server $serverName

# check role of secondary replica (note ReplicationRole property)
echo "Confirming the secondary server is secondary...." 
az sql failover-group show --name $failoverGroupName \
   --resource-group $resourceGroupName

# failover to secondary server
echo "Failing over failover group to the secondary..." 
az sql failover-group set-primary --name $failoverGroupName \
   --resource-group $resourceGroupName \
   --server $drServerName 
echo "Failover group failed over to" $drServerName

# check role of secondary replica (note ReplicationRole property)
echo "Confirming the secondary server is now primary..." 
az sql failover-group show --name $failoverGroupName \
   --resource-group $resourceGroupName

# revert failover to primary server
echo "Failing over failover group to the primary...." 
az sql failover-group set-primary --name $failoverGroupName \
   --resource-group $resourceGroupName \
   --server $serverName
echo "Failover group failed over to" $serverName 

# clean up resources by removing the resource group
# echo "Removing resource group..."
# az group delete --name $resourceGroupName
# echo "Resource group removed"
