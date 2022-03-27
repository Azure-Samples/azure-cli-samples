#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Configure same-zone high availability

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="same-zone-ha-mysql"
server="msdocs-mysql-server-$randomIdentifier"
sku="Standard_D2ds_v4"
tier="GeneralPurpose"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
ipAddress="None"
# Specifying an IP address of 0.0.0.0 allows public access from any resources
# deployed within Azure to access your server. Setting it to "None" sets the server 
# in public access mode but does not create a firewall rule.
# For your public IP address, https://whatismyipaddress.com

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Enable Same-zone HA while creating a MySQL Flexible server in the resource group
# HA is not available for burstable tier
# HA cannot be enabled post create
echo "Creating $server"
az mysql flexible-server create --name $server --resource-group $resourceGroup \
--location "$location" --sku-name $sku --tier $tier --admin-user $login --admin-password $password \
--public-access $ipAddress --high-availability SameZone

# Optional: Add firewall rule to connect from all Azure services
# To limit to a specific IP address or address range, change start-ip-address and end-ip-address
echo "Adding firewall for IP address range"
az mysql flexible-server firewall-rule create --name $server --resource-group $resourceGroup --rule-name AllowAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Disable Same-zone HA
echo "Disabling same-zone HA"
az mysql flexible-server update --resource-group $resourceGroup --name $server --high-availability Disabled
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
