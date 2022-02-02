#!/bin/bash
# Passed validation in Cloud Shell 02/01/2022

let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="peer-two-virtual-networks"
vNet="msdocs-vNet-$randomIdentifier"
addressPrefixVNet="10.0.0.0/16"
subnetFrontEnd="msdocs-frontend-subnet-$randomIdentifier"
subnetPrefixFrontEnd="10.0.1.0/24"
nsgFrontEnd="msdocs-nsg-frontend-$randomIdentifier"
subnetBackEnd="msdocs-backend-subnet-$randomIdentifier"
subnetPrefixBackEnd="10.0.2.0/24"
nsgBackEnd="msdocs-nsg-backend-$randomIdentifier"
publicIpWeb="msdocs-public-ip-web-$randomIdentifier"
publicIpSql="msdocs-public-ip-sql-$randomIdentifier"
nicWeb="msdocs-nic-web-$randomIdentifier"
nicSql="msdocs-nic-sql-$randomIdentifier"
image="UbuntuLTS"
login="image"
vmWeb="msdocs-vm-web-virtual-network-$randomIdentifier"
vmSql="msdocs-vm-sql-virtual-network-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a virtual network and a front-end subnet.
echo "Creating $vNet and $subnetFrontEnd"
az network vnet create --resource-group $resourceGroup --name $vNet --address-prefix $addressPrefixVNet  --location "$location" --subnet-name $subnetFrontEnd --subnet-prefix $subnetPrefixFrontEnd

# Create a back-end subnet.
echo "Creating $subnetBackEnd"
az network vnet subnet create --address-prefix $subnetPrefixBackEnd --name $subnetBackEnd --resource-group $resourceGroup --vnet-name $vNet

# Create a network security group (NSG) for the front-end subnet.
echo "Creating $nsgFrontEnd for $subnetFrontEnd"
az network nsg create --resource-group $resourceGroup --name $nsgFrontEnd --location "$location"

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
echo "Creating $nsgFrontEnd rules to allow HTTP and HTTPS inbound traffic"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80

az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443

# Create an NSG rule to allow SSH traffic in from the Internet to the front-end subnet.
echo "Creating NSG rule to allow inbound SSH traffic"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22

# Associate the front-end NSG to the front-end subnet.
echo "Associate $subnetFrontEnd to $nsgFrontEnd"
az network vnet subnet update --vnet-name $vNet --name $subnetFrontEnd --resource-group $resourceGroup --network-security-group $nsgFrontEnd

# Create a network security group for the back-end subnet.
echo "Creating $nsgBackEnd for $subnetBackEnd"
az network nsg create --resource-group $resourceGroup --name $nsgBackEnd --location "$location"

# Create an NSG rule to allow MySQL traffic from the front-end subnet to the back-end subnet.
echo "Creating NSG rule to allow MySQL traffic from $subnetFrontEnd to $subnetBackEnd"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgBackEnd --name Allow-MySql-FrontEnd --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix $subnetPrefixFrontEnd --source-port-range "*" --destination-address-prefix "*" --destination-port-range 3306

# Create an NSG rule to allow SSH traffic from the Internet to the back-end subnet.
echo "Creating NSG rule to allow SSH traffic from the Internet to $subnetBackEnd"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgBackEnd --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22

# Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (NOTE: If you run the MySQL installation below this rule will be disabled and then re-enabled).
echo "Creating NSG rule to block all outbound traffic from $subnetBackEnd"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgBackEnd --name Deny-Internet-All --access Deny --protocol Tcp --direction Outbound --priority 300 --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range "*"

# Associate the back-end NSG to the back-end subnet.
echo "Associate $nsgBackEnd to $subnetBackEnd"
az network vnet subnet update --vnet-name $vNet --name $subnetBackEnd --resource-group $resourceGroup --network-security-group $nsgBackEnd

# Create a public IP address for the web server VM.
echo "Creating $publicIpWeb for $vmWeb"
az network public-ip create --resource-group $resourceGroup --name $publicIpWeb

# Create a NIC for the web server VM.
echo "Creating $nicWeb for $vmWeb"
az network nic create --resource-group $resourceGroup --name $nicWeb --vnet-name $vNet --subnet $subnetFrontEnd --network-security-group $nsgFrontEnd --public-ip-address $publicIpWeb

# Create a Web Server VM in the front-end subnet.
echo "Creating $vmWeb in $subnetFrontEnd"
az vm create --resource-group $resourceGroup --name $vmWeb --nics $nicWeb --image $image --admin-username $login --generate-ssh-keys  --public-ip-sku Standard

# Create a public IP address for the MySQL VM.
echo "Creating $publicIpSql for $vmSql"
az network public-ip create --resource-group $resourceGroup --name $publicIpSql

# Create a NIC for the MySQL VM.
echo "Creating $nicSql for $vmSql"
az network nic create --resource-group $resourceGroup --name $nicSql --vnet-name $vNet --subnet $subnetBackEnd --network-security-group $nsgBackEnd --public-ip-address $publicIpSql

# Create a MySQL VM in the back-end subnet.
echo "Creating $vmSql in $subnetBackEnd"
az vm create --resource-group $resourceGroup --name $vmSql --nics $nicSql --image $image --admin-username $login --generate-ssh-keys  --public-ip-sku Standard

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
