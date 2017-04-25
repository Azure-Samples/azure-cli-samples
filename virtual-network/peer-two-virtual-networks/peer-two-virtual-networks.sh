#!/bin/bash

RgName="MyResourceGroup"
Location="westus"

# Create a resource group.
az group create \
  --name $RgName \
  --location $Location

# Create virtual network 1.
az network vnet create \
  --name Vnet1 \
  --resource-group $RgName \
  --location $Location \
  --address-prefix 10.0.0.0/16

# Create virtual network 2.
az network vnet create \
  --name Vnet2 \
  --resource-group $RgName \
  --location $Location \
  --address-prefix 10.1.0.0/16

# Get the id for VNet1.
VNet1Id=$(az network vnet show \
  --resource-group $RgName \
  --name Vnet1 \
  --query id --out tsv)

# Get the id for VNet2.
VNet2Id=$(az network vnet show \
  --resource-group $RgName \
  --name Vnet2 \
  --query id \
  --out tsv)

# Peer VNet1 to VNet2.
az network vnet peering create \
  --name LinkVnet1ToVnet2 \
  --resource-group $RgName \
  --vnet-name VNet1 \
  --remote-vnet-id $VNet2Id

# Peer VNet2 to VNet1.
az network vnet peering create \
  --name LinkVnet2ToVnet1 \
  --resource-group $RgName \
  --vnet-name VNet2 \
  --remote-vnet-id $VNet1Id
