#!/bin/bash

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a virtual network and subnet (front end).
az network vnet create --resource-group myResourceGroup --location westus --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnetFrontEnd --subnet-prefix 192.168.1.0/24

# Create a subnet (back end) and associate with virtual network. 
az network vnet subnet create --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetBackEnd --address-prefix 192.168.2.0/24

# Create a public IP address and specify a DNS name.
az network public-ip create --resource-group myResourceGroup --location westus \
  --name myPublicIP --dns-name mypublicdns$RANDOM --allocation-method static --idle-timeout 4

# Create a network security group.
az network nsg create --resource-group myResourceGroup --location westus \
  --name myNetworkSecurityGroupFrontEnd

# Create an inbound network security group rule for port 3389.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupFrontEnd --name myNetworkSecurityGroupRuleFrontEndRDP \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 \
  --access allow

# Create an inbound network security group rule for port 80.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupFrontEnd --name myNetworkSecurityGroupRuleFrontEndHTTP \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 \
  --access allow

# Associate network security group with subnet. 
az network vnet subnet update --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetFrontEnd --network-security-group myNetworkSecurityGroupFrontEnd

# Create a network security group.
az network nsg create --resource-group myResourceGroup --location westus \
  --name myNetworkSecurityGroupBackEnd

# Create an inbound network security group rule for port 22.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupBackEnd --name myNetworkSecurityGroupRuleBackEndRDP \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix 192.168.1.0/24 \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 \
  --access allow

# Create an inbound network security group rule for MongoDB port 27017.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupBackEnd --name myNetworkSecurityGroupRuleBackEndMongoDB \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix 192.168.1.0/24 \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 27017 \
  --access allow

# Associate network security group with subnet. 
az network vnet subnet update --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetBackEnd --network-security-group myNetworkSecurityGroupBackEnd

# Create a virtual network card and associate with front end subnet and public IP address.
az network nic create --resource-group myResourceGroup --location westus --name myNic1 \
    --vnet-name myVnet --subnet mySubnetFrontEnd --public-ip-address myPublicIP

# Create a virtual network card and associate with back end subnet.
az network nic create --resource-group myResourceGroup --location westus --name myNic2 \
    --vnet-name myVnet --subnet mySubnetBackEnd

# Create a virtual machine. 
az vm create \
    --resource-group myResourceGroup \
    --name myVMFrontEnd \
    --location westus \
    --nics myNic1 \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword \
    --no-wait

# Create a virtual machine. 
az vm create \
    --resource-group myResourceGroup \
    --name myVMBackEnd \
    --location westus \
    --nics myNic1 \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword \
    --no-wait