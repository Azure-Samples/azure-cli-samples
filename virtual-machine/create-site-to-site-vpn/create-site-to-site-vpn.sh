#!/bin/bash

# Variables
resourceGroupName=Vnet-Vnet

location1=westus
VNET1=TestVnet1
VNET1Prefix=10.1.0.0/16
VNET1Subnet=vNet1SubnetName
VNET1SubnetPrefix=10.1.1.0/24
GW1=GWVNet1
GW1Subnet=10.1.255.0/27
GW1PubIP=GWVNet1-PubIP
Conn1=GW1GW2

location2=eastus
VNET2=TestVnet2
VNET2Prefix=10.11.0.0/16
VNET2Subnet=vNet2SubnetName
VNET2SubnetPrefix=10.11.1.0/24
GW2=GWVNet2
GW2Subnet=10.11.255.0/27
GW2PubIP=GWVNet2-PubIP
Conn2=GW2GW1

SharedKey="connection"

# Create a resource group.
az group create --name $resourceGroupName --location $location1

# Create VNet1
az network vnet create \
  --resource-group $resourceGroupName \
  --location $location1 \
  --name $VNET1 \
  --address-prefix $VNET1Prefix \
  --subnet-name $VNET1Subnet \
  --subnet-prefix $VNET1SubnetPrefix

# Create Vnet 2
az network vnet create \
  --resource-group $resourceGroupName \
  --location $location2 \
  --name $VNET2 \
  --address-prefix \
  $VNET2Prefix \
  --subnet-name $VNET2Subnet \
  --subnet-prefix $VNET2SubnetPrefix

# Create the public IPs for the Gateways in the two regions
az network public-ip create -n $GW1PubIP -g $resourceGroupName -l $location1
az network public-ip create -n $GW2PubIP -g $resourceGroupName -l $location2

# Create the Gateway Subnets on each of the two vnets
az network vnet subnet create \
  --address-prefix $GW1Subnet \
  -n GatewaySubnet \
  -g $resourceGroupName \
  --vnet-name $VNET1

az network vnet subnet create \
  --address-prefix $GW2Subnet 
  -n GatewaySubnet 
  -g $resourceGroupName 
  --vnet-name $VNET2

# Create the VPN Gateways on each vnet 
az network vnet-gateway create \
  -n $GW1 \
  --public-ip-address $GW1PubIP \
  -l $location1 \
  -g $resourceGroupName \
  --vnet $VNET1 \
  --gateway-type Vpn \
  --sku Standard

az network vnet-gateway create \
  -n $GW2 \
  --public-ip-address $GW2PubIP \
  -l $location2 \
  -g $resourceGroupName \
  --vnet $VNET2 \
  --gateway-type Vpn \
  --sku Standard

# Establish connetion between 
az network vpn-connection create \
  -n $Conn1 \
  -g $resourceGroupName \ 
  --vnet-gateway1 $GW1 \
  -l $location1 \
  --shared-key $SharedKey \
  --vnet-gateway2 $GW2

az network vpn-connection create \
  -n $Conn2 \
  -g $resourceGroupName \
  --vnet-gateway1 $GW2 \
  -l $location2 \
  --shared-key $SharedKey \
  --vnet-gateway2 $GW1
