#!/bin/bash
# Passed validation in Bash in Docker container on Windows 02/11/2021

# <FullScript>
# Restore a Managed Instance database to another geo-region
# Use Bash rather than Cloud Shell due to its timeout at 20 minutes when no interactive activity 
# In Windows, run Bash in a Docker container to sync time zones between Azure and Bash.

# Run this script after running the script in https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/scripts/create-configure-managed-instance-cli twice to create two managed instances
# Provide the values for these three variables before running this rest of this script

# Variable block for additional parameter values
$instance = "<msdocs-azuresql-instance>" # add instance here
$targetInstance = "<msdocs-azuresql-target-instance>" # add target instance here
$resourceGroup = "<msdocs-azuresql-rg>" # add resource here

let "randomIdentifier=$RANDOM*$RANDOM"
$managedDatabase = "managedDatabase-$randomIdentifier"

echo "Creating $($managedDatabase) on $($instance)..."
az sql midb create -g $resourceGroup --mi $instance -n $managedDatabase

# Sleeping commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 40m

# To specify a specific point-in-time (in UTC) to restore from, use the ISO8601 format:
# restorePoint=“2021-07-09T13:10:00Z”
restorePoint=$(date +%s)
restorePoint=$(expr $restorePoint - 60)
restorePoint=$(date -d @$restorePoint +"%Y-%m-%dT%T")
echo $restorePoint

echo "Restoring $($managedDatabase) to $($targetInstance)..."
az sql midb restore -g $resourceGroup --mi $instance -n $managedDatabase --dest-name $targetInstance --time $restorePoint

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
