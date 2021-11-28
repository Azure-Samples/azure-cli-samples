#!/bin/bash
# Passed validation in Cloud Shell 11/17/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"

startIP=0.0.0.0
endIP=0.0.0.0

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Configuring firewall..."
az sql server firewall-rule create --resource-group $resource --server $server -n AllowYourIp --start-ip-address $startIP --end-ip-address $endIP

echo "Creating $database on $server..."
az sql db create --resource-group $resource --server $server --name $database --sample-name AdventureWorksLT --edition GeneralPurpose --family Gen5 --capacity 2 --zone-redundant true # zone redundancy is only supported on premium and business critical service tiers

# echo "Deleting all resources"
# az group delete --name $resource -y
