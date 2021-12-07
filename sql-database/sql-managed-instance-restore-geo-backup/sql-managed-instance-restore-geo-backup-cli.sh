#!/bin/bash
# Passed validation in Cloud Shell 12/07/2021

$instance = "<msdocs-azuresql-instance>" # add instance here
$targetInstance = "<msdocs-azuresql-target-instance>" # add target instance here
$resourceGroup = "<msdocs-azuresql-rg>" # add resource here

let randomIdentifier=$RANDOM*$RANDOM
$managedDatabase = "managedDatabase-$randomIdentifier"

echo "Creating $($managedDatabase) on $($instance)..."
az sql midb create -g $resourceGroup --mi $instance -n $managedDatabase

# Sleeping  commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 40m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

echo "Restoring $($managedDatabase) to $($targetInstance)..."
az sql midb restore -g $resourceGroup --mi $instance -n $managedDatabase --dest-name $targetInstance --time $restoreDateTime

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y