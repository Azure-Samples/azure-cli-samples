#!/bin/bash

RgName="MyResourceGroup"
Location="westus"

# Create a resource group.
az group create \
  --name $RgName \
  --location $Location

# Create a virtual network with a front-end subnet.
az network vnet create \
  --name MyVnet \
  --resource-group $RgName \
  --location $Location \
  --address-prefix 10.0.0.0/16 \
  --subnet-name MySubnet-FrontEnd \
  --subnet-prefix 10.0.1.0/24

# Create a back-end subnet.
az network vnet subnet create \
  --address-prefix 10.0.2.0/24 \
  --name MySubnet-BackEnd \
  --resource-group $RgName \
  --vnet-name MyVnet

# Create a network security group for the front-end subnet.
az network nsg create \
  --resource-group $RgName \
  --name MyNsg-FrontEnd \
  --location $Location

# Create an NSG rule to allow HTTP traffic in from the Internet to the front-end subnet.
az network nsg rule create \
  --resource-group $RgName \
  --nsg-name MyNsg-FrontEnd \
  --name Allow-HTTP-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 100 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 80

# Create an NSG rule to allow SSH traffic in from the Internet to the front-end subnet.
az network nsg rule create \
  --resource-group $RgName \
  --nsg-name MyNsg-FrontEnd \
  --name Allow-SSH-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 300 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 22

# Associate the front-end NSG to the front-end subnet.
az network vnet subnet update \
  --vnet-name MyVnet \
  --name MySubnet-FrontEnd \
  --resource-group $RgName \
  --network-security-group MyNsg-FrontEnd

# Create a network security group for back-end subnet.
az network nsg create \
  --resource-group $RgName \
  --name MyNsg-BackEnd \
  --location $Location

# Create an NSG rule to allow MySQL traffic from the front-end subnet to the back-end subnet.
az network nsg rule create \
  --resource-group $RgName \
  --nsg-name MyNsg-BackEnd \
  --name Allow-MySql-FrontEnd \
  --access Allow --protocol Tcp \
  --direction Inbound \
  --priority 100 \
  --source-address-prefix 10.0.1.0/24 \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 3306

# Create an NSG rule to allow SSH traffic from the Internet to the front-end subnet.
az network nsg rule create \
  --resource-group $RgName \
  --nsg-name MyNsg-BackEnd \
  --name Allow-SSH-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 200 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 22

# Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (NOTE: If you run the MySQL installation below this rule will be disabled and then re-enabled).
az network nsg rule create \
  --resource-group $RgName \
  --nsg-name MyNsg-BackEnd \
  --name Deny-Internet-All \
  --access Deny --protocol Tcp \
  --direction Outbound --priority 300 \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range "*"

# Associate the back-end NSG to the back-end subnet.
az network vnet subnet update \
  --vnet-name MyVnet \
  --name MySubnet-BackEnd \
  --resource-group $RgName \
  --network-security-group MyNsg-BackEnd

# Create a public IP address for the web server VM.
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIP-Web

# Create a NIC for the web server VM.
az network nic create \
  --resource-group $RgName \
  --name MyNic-Web \
  --vnet-name MyVnet \
  --subnet MySubnet-FrontEnd \
  --network-security-group MyNsg-FrontEnd \
  --public-ip-address MyPublicIP-Web

# Create a Web Server VM in the front-end subnet.
az vm create \
  --resource-group $RgName \
  --name MyVm-Web \
  --nics MyNic-Web \
  --image UbuntuLTS \
  --generate-ssh-keys

# Create a public IP address for the MySQL VM.
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIP-Sql

# Create a NIC for the MySQL VM.
az network nic create \
  --resource-group $RgName \
  --name MyNic-Sql \
  --vnet-name MyVnet \
  --subnet MySubnet-BackEnd \
  --network-security-group MyNsg-BackEnd \
  --public-ip-address MyPublicIP-Sql

# Create a MySQL VM in the back-end subnet.
az vm create \
  --resource-group $RgName \
  --name MyVm-Sql \
  --nics MyNic-Sql \
  --image UbuntuLTS \
  --generate-ssh-keys
