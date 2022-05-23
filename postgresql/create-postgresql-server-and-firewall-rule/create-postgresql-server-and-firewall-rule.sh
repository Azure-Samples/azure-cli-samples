#!/bin/bash
# Passed validation in Cloud Shell on 1/13/2022

# <FullScript>
# Create an Azure Database for PostgreSQL server and configure a firewall rule

# <SetParameterValues>
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-postgresql-rg-$randomIdentifier"
tag="create-postgresql-server-and-firewall-rule"
server="msdocs-postgresql-server-$randomIdentifier"
sku="GP_Gen5_2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
# Specify appropriate IP address values for your environment
# to limit / allow access to the PostgreSQL server
startIp=0.0.0.0
endIp=0.0.0.0
echo "Using resource group $resourceGroup with login: $login, password: $password..."
# </SetParameterValues>
# <CreateResourceGroup>
# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag
# </CreateResourceGroup>
# <CreateServer>
# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az postgres server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku
# </CreateServer>
# <CreateFirewallRule>
# Configure a firewall rule for the server 
echo "Configuring a firewall rule for $server for the IP address range of $startIp to $endIp"
az postgres server firewall-rule create --resource-group $resourceGroup --server $server --name AllowIps --start-ip-address $startIp --end-ip-address $endIp
# </CreateFirewallRule>
# <ListFirewallRules>
# List firewall rules for the server
echo "List of server-based firewall rules for $server"
az postgres server firewall-rule list --resource-group $resourceGroup --server-name $server
# You may use the switch `--output table` for a more readable table format as the output.
# </ListFirewallRules>
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
