#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Monitor your MySQLFlexible Server and scale compute, storage, and IOPS

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
subscriptionId="$(az account show --query id -o tsv)"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="monitor-and-scale-mysql"
server="msdocs-mysql-server-$randomIdentifier"
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

# Create a MySQL Flexible server in the resource group
echo "Creating $server"
az mysql flexible-server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --public-access $ipAddress

# Optional: Add firewall rule to connect from all Azure services
# To limit to a specific IP address or address range, change start-ip-address and end-ip-address
echo "Adding firewall for IP address range"
az mysql flexible-server firewall-rule create --name $server --resource-group $resourceGroup --rule-name AllowAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Monitor CPU percent, storage usage and IO percent

# Monitor CPU Usage metric
echo "Monitor CPU usage"
az monitor metrics list \
    --resource "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DBforMySQL/flexibleservers/$server" \
    --metric cpu_percent \
    --interval PT1M

# Monitor Storage usage metric
echo "Monitor storage usage"
az monitor metrics list \
    --resource "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DBforMySQL/flexibleservers/$server" \
    --metric storage_used \
    --interval PT1M

# Monitor IO Percent
echo "Monitor I/O percent"
az monitor metrics list \
    --resource "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DBforMySQL/flexibleservers/$server" \
    --metric io_consumption_percent \
    --interval PT1M

# Scale up the server by provisionining to higher tier from Burstable to General purpose 4vcore
echo "Scale up to Standard_D4ds_v4"
az mysql flexible-server update \
    --resource-group $resourceGroup \
    --name $server \
    --sku-name Standard_D4ds_v4 \
    --tier GeneralPurpose 

# Scale down to by provisioning to General purpose 2vcore within the same tier
echo "Scale down to Standard_D2ds_v4"
az mysql flexible-server update \
    --resource-group $resourceGroup \
    --name $server \
    --sku-name Standard_D2ds_v4

# Scale up the server to provision a storage size of 64GB. Note storage size cannot be reduced.
echo "Scale up storage to 64 GB"
az mysql flexible-server update \
    --resource-group $resourceGroup \
    --name $server \
    --storage-size 64

# Scale IOPS
echo "Scale IOPS to 550"
az mysql flexible-server update \
    --resource-group $resourceGroup \
    --name $server \
    --iops 550
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
