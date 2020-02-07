#!/bin/bash

# Connect-AzAccount

$subscriptionId = ''
$primaryResourceGroupName = "myPrimaryResourceGroup-$(Get-Random)"
$primaryLocation = "westus2"
$secondaryResourceGroupName = "mySecondaryResourceGroup-$(Get-Random)"
$secondaryLocation = "eastus"
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
$primaryServerName = "primary-server-$(Get-Random)"
$secondaryServerName = "secondary-server-$(Get-Random)"
$databaseName = "mySampleDatabase"

# The ip address range that you want to allow to access your servers
$primaryStartIp = "0.0.0.0"
$primaryEndIp = "0.0.0.0"
$secondaryStartIp = "0.0.0.0"
$secondaryEndIp = "0.0.0.0"

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create two new resource groups
az group create \
   --name $primaryResourceGroupName \
   --location $primaryLocation
az group create \
   --name $secondaryResourceGroupname \
   --location $secondaryLocation

# create two new logical servers with a system wide unique server name
az sql server create \
   --name $primaryServerName \
   --resource-group $primaryResourceGroupName \
   --location $primaryLocation  \
   --admin-user $adminSqlLogin \
   --admin-password $password
az sql server create \
   --name $secondaryServerName \
   --resource-group $secondaryResourceGroupName \
   --location $secondaryLocation  \
   --admin-user $adminSqlLogin \
   --admin-password $password

# create a server firewall rule for each server that allows access from the specified IP range
az sql server firewall-rule create --end-ip-address $primaryEndIp \
   --name "AllowedIPs" \
   --resource-group $primaryResourceGroupName \
   --server $primaryservername \
   --start-ip-address $primaryStartIp 

az sql server firewall-rule create --end-ip-address $secondaryEndIp \
   --name "AllowedIPs" \
   --resource-group $secondaryResourceGroupName \
   --server $secondaryservername \
   --start-ip-address $secondaryStartIp 

# create a blank database with S0 performance level on the primary server
az sql db create --name $databaseName \
   --resource-group $primaryResourceGroupName \
   --server $primaryServerName \
   --service-objective S0

# establish Active Geo-Replication
az sql db replica create --name $databaseName \
    --partner-server $secondaryServerName \
    --resource-group $primaryResourceGroupName \
    --server $primaryServerName \
    --partner-resource-group $secondaryResourceGroupName

# initiate a planned failover
az sql failover-group set-primary --name $databaseName
    --resource-group $secondaryResourceGroupName
    --server $secondaryServerName

# monitor Geo-Replication config and health after failover
az sql db replica list-links --name $databaseName \
    --resource-group $primaryResourceGroupName \
    --server $primaryServerName

# remove the replication link after the failover
az sql db replica delete-link --partner-server $primaryServerName \
    --name $databaseName \
    --partner-resource-group $primaryResourceGroupName \
    --resource-group $secondaryResourceGroupName \
    --server $secondaryServerName

# clean up deployment 
# az group delete --name $primaryResourceGroupName
# az group delete --name $secondaryResourceGroupName