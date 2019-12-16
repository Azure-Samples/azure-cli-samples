#!/bin/bash
# Set variables
subscriptionID=<subscriptionId>
resourceGroupName=myResourceGroup-$RANDOM
location=westus2
adminLogin=SqlAdmin
password="ChangeYourAdminPassword1"
serverName=server-$RANDOM
databaseName=mySampleDatabase
restoreDatabaseName=MySampleDatabase_GeoRestore
pointInTimeRestoreDatabaseName=MySampleDatabase_10MinutesAgo

# The ip address range that you want to allow access to your DB. 
# Leaving at 0.0.0.0 will prevent outside-of-azure connections
startip=0.0.0.0
endip=0.0.0.0

# Set the subscription context for the Azure account
az account set -s $subscriptionID

# Create a resource group
az group create \
   --name $resourceGroupName \
   --location $location

# Create a logical server in the resource group
az sql server create \
   --name $serverName \
   --resource-group $resourceGroupName \
   --location $location  \
   --admin-user $adminLogin \
   --admin-password $password

# Configure a firewall rule for the server
az sql server firewall-rule create \
   --resource-group $resourceGroupName \
   --server $serverName \
   -n AllowYourIp \
   --start-ip-address $startip \
   --end-ip-address $endip

# Create a blank database with an S0 performance level
echo "Creating a gen5 2 vCore database..."
az sql db create \
   --resource-group $resourceGroupName \
   --server $serverName \
   --name $databaseName \
   --service-objective S0

Start-Sleep -second 600
$restoreDateTime = (Get-Date).ToUniversalTime().AddMinutes(-2)
$azRestoreTime = '{0:s}' -f $restoreDateTime

# Restore database to its state 7 minutes ago
# Note: Point-in-time restore requires database to be at least 5 minutes old
az sql db restore --dest-name $pointInTimeRestoreDatabaseName \
   --edition Standard \
   --ids \
   --name $restoreDatabaseName \
   --resource-group $resourceGroupName \
   --server $serverName \
   --service-objective S0 \
   --time $azRestoreTime


      -ResourceId $database.ResourceID `


# Clean up resources by removing the resource group
# echo "Cleaning up resources by removing the resource group..."
# az group delete \
#   --name $resourceGroupName 
# echo "Successfully removed resource group" $resourceGroupName
