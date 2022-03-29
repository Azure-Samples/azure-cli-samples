#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Add an Azure SQL Database elastic pool to a failover group
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="add-elastic-pool-to-failover-group-az-cli"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
# <SetPoolParameterValues>
pool="msdocs-azuresql-pool-$randomIdentifier"
# </SetPoolParameterValues>
# <SetFailoverParameterValues>
failoverGroup="msdocs-azuresql-failover-group-$randomIdentifier"
failoverLocation="Central US"
secondaryServer="msdocs-azuresql-secondary-server-$randomIdentifier"
# </SetFailoverParameterValues>
echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location"  --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resourceGroup --server $server --sample-name AdventureWorksLT

# <CreateElasticPool>
echo "Creating $pool on $server..."
az sql elastic-pool create --name $pool --resource-group $resourceGroup --server $server
# </CreateElasticPool>
# <AddDatabaseToPool>
echo "Adding $database to $pool..."
az sql db update --elastic-pool $pool --name $database --resource-group $resourceGroup --server $server
# </AddDatabaseToPool>
# <CreateSecondaryServer>
echo "Creating $secondaryServer in $failoverLocation..."
az sql server create --name $secondaryServer --resource-group $resourceGroup --location "$failoverLocation"  --admin-user $login --admin-password $password
# </CreateSecondaryServer>
# <CreateElasticPoolOnSecondary>
echo "Creating $pool on $secondaryServer..."
az sql elastic-pool create --name $pool --resource-group $resourceGroup --server $secondaryServer
# </CreateElasticPoolOnSecondary>
# <CreateFailoverGroup>
echo "Creating $failoverGroup between $server and $secondaryServer..."
az sql failover-group create --name $failoverGroup --partner-server $secondaryServer --resource-group $resourceGroup --server $server --failover-policy Automatic --grace-period 2
databaseId=$(az sql elastic-pool list-dbs --name $pool --resource-group $resourceGroup --server $server --query [0].name -o json | tr -d '"')
# </CreateFailoverGroup>
# <AddDatabaseToFailoverGroup>
echo "Adding $database to $failoverGroup..."
az sql failover-group update --name $failoverGroup --add-db $databaseId --resource-group $resourceGroup --server $server
# </AddDatabaseToFailoverGroup>
# <VerifyRoles>
echo "Confirming the role of each server in the failover group..." # note ReplicationRole property
az sql failover-group show --name $failoverGroup --resource-group $resourceGroup --server $server
# </VerifyRoles>
# <FailingOver>
echo "Failing over to $secondaryServer..."
az sql failover-group set-primary --name $failoverGroup --resource-group $resourceGroup --server $secondaryServer 

echo "Confirming role of $secondaryServer is now primary..." # note ReplicationRole property
az sql failover-group show --name $failoverGroup --resource-group $resourceGroup --server $server
# </FailingOver>
# <FailingBack>
echo "Failing back to $server...."
az sql failover-group set-primary --name $failoverGroup --resource-group $resourceGroup --server $server
# </FailingBack>

# </FullScript>
# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
