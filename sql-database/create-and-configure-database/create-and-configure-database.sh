#!/bin/bash
location="East US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"

login="sampleLogin"
password="samplePassword123!"

startIP=0.0.0.0
endIP=0.0.0.0

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Configuring firewall..."
az sql server firewall-rule create --resource-group $resource --server $server -n AllowYourIp --start-ip-address $startIP --end-ip-address $endIP

echo "Creating $database on $server..."
az sql db create --resource-group $resource --server $server --name $database --sample-name AdventureWorksLT --edition GeneralPurpose --family Gen4 --capacity 1 --zone-redundant false # zone redundancy is only supported on premium and business critical service tiers