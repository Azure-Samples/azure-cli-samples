#!/bin/bash
# Set variables
export subscriptionID=<SubscriptionID>
export resourceGroupName=myResourceGroup-$RANDOM
export location=WestUS2
export adminLogin=azureuser
export password=`openssl rand -base64 16`
export serverName=mysqlserver-$RANDOM
export databaseName=mySampleDatabase
export drLocation=EastUS2
export drServerName=mysqlsecondary-$RANDOM
export failoverGroupName=failovergrouptutorial-$RANDOM

# The ip address range that you want to allow access to your DB. 
# Leaving at 0.0.0.0 will prevent outside-of-azure connections
export startip=0.0.0.0
export endip=0.0.0.0

# Print out randomized variables
echo $resourceGroupName
echo $password
echo $serverName
echo $drServerName
echo $failoverGroupName

# Connect to Azure
echo "Connecting to azure..."
az login
$ Set subscription ID
az account set --subscription $subscriptionID

# Create a resource group
echo "Creating resource group..."
az group create \
   --name $resourceGroupName \
   --location $location \
   --tags Owner[=SQLDB-Samples]

# Create a logical server in the resource group
echo "Creating primary logical server..."
az sql server create \
   --name $serverName \
   --resource-group $resourceGroupName \
   --location $location  \
   --admin-user $adminLogin \
   --admin-password $password

# Configure a firewall rule for the server
echo "Configuring firewall..."
az sql server firewall-rule create \
   --resource-group $resourceGroupName \
   --server $serverName \
   -n AllowYourIp \
   --start-ip-address $startip \
   --end-ip-address $endip

# Create a gen5 1vCore database in the server 
echo "Creating a gen5 1 vCore database..."
az sql db create \
   --resource-group $resourceGroupName \
   --server $serverName \
   --name $databaseName \
   --sample-name AdventureWorksLT \
   --edition GeneralPurpose \
   --family Gen5 \
   --capacity 1 

# Create a secondary server in the failover region
echo "Creating a secondary logical server in the DR region..."
az sql server create \
   --name $drServerName \
   --resource-group $resourceGroupName \
   --location $drLocation  \
   --admin-user $adminLogin\
   --admin-password $password

# Create a failover group between the servers and add the database
echo "Creating a failover group between the two servers..."
az sql failover-group create \
   --name $failoverGroupName  \
   --partner-server $drServerName \
   --resource-group $resourceGroupName \
   --server $serverName \
   --failover-policy Automatic 

# Verify which server is secondary
echo "Verifying which server is in the secondary role..."
az sql failover-group list \
   --server $serverName \
   --resource-group $resourceGroupName 

# Failover to the secondary server
echo "Failing over group to the secondary server..."
az sql failover-group set-primary \
   --name $failoverGroupName \
   --resource-group $resourceGroupName \
   --server $drServerName 
echo "Successfully failed failover group over to" $drServerName

# Revert failover group back to the primary server
echo "Failing over group back to the primary server..."
az sql failover-group set-primary \
   --name $failoverGroupName \
   --resource-group $resourceGroupName \
   --server $serverName 
echo "Successfully failed failover group back to" $serverName

# Clean up resources by removing the resource group
echo "Cleaning up resources by removing the resource group..."
az group delete \
   --name $resourceGroupName 
echo "Successfully removed resource group" $resourceGroupName
