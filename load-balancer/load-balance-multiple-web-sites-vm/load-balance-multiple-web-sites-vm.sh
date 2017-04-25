#!/bin/bash

RgName="MyResourceGroup"
Location="westus"

# Create a resource group.
az group create \
  --name $RgName \
  --location $Location

# Create an availability set for the two VMs that host both websites.
az vm availability-set create \
  --resource-group $RgName \
  --location $Location \
  --name MyAvailabilitySet \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 2

# Create a virtual network and a subnet.
az network vnet create \
  --resource-group $RgName \
  --name MyVnet \
  --address-prefix 10.0.0.0/16 \
  --location $Location \
  --subnet-name MySubnet \
  --subnet-prefix 10.0.0.0/24

# Create three public IP addresses; one for the load balancer and two for the front-end IP configurations.
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIp-LoadBalancer \
  --allocation-method Dynamic
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIp-Contoso \
  --allocation-method Dynamic
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIp-Fabrikam \
  --allocation-method Dynamic

# Create a load balancer.
az network lb create \
  --resource-group $RgName \
  --location $Location \
  --name MyLoadBalancer \
  --frontend-ip-name FrontEnd \
  --backend-pool-name BackEnd \
  --public-ip-address MyPublicIp-LoadBalancer

# Create two front-end IP configurations for both web sites.
az network lb frontend-ip create \
  --resource-group $RgName \
  --lb-name MyLoadBalancer \
  --public-ip-address MyPublicIp-Contoso \
  --name FeContoso
az network lb frontend-ip create \
  --resource-group $RgName \
  --lb-name MyLoadBalancer \
  --public-ip-address MyPublicIp-Fabrikam \
  --name FeFabrikam

# Create the back-end address pools.
az network lb address-pool create \
  --resource-group $RgName \
  --lb-name MyLoadBalancer \
  --name BeContoso
az network lb address-pool create \
  --resource-group $RgName \
  --lb-name MyLoadBalancer \
  --name BeFabrikam

# Create a probe on port 80.
az network lb probe create \
  --resource-group $RgName \
  --lb-name MyLoadBalancer \
  --name MyProbe \
  --protocol Http \
  --port 80 --path /

# Create the load balancing rules.
az network lb rule create \
  --resource-group $RgName \
  --lb-name MyLoadBalancer \
  --name LBRuleContoso \
  --protocol Tcp \
  --probe-name MyProbe \
  --frontend-port 5000 \
  --backend-port 5000 \
  --frontend-ip-name FeContoso \
  --backend-pool-name BeContoso
az network lb rule create \
  --resource-group $RgName \
  --lb-name MyLoadBalancer \
  --name LBRuleFabrikam \
  --protocol Tcp \
  --probe-name MyProbe \
  --frontend-port 5000 \
  --backend-port 5000 \
  --frontend-ip-name FeFabrikam \
  --backend-pool-name BeFabrikam

# ############## VM1 ###############

# Create an Public IP for the first VM.
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIp-Vm1 \
  --allocation-method Dynamic

# Create a network interface for VM1.
az network nic create \
  --resource-group $RgName \
  --vnet-name MyVnet \
  --subnet MySubnet \
  --name MyNic-Vm1 \
  --public-ip-address MyPublicIp-Vm1

# Create IP configurations for Contoso and Fabrikam.
az network nic ip-config create \
  --resource-group $RgName \
  --name ipconfig2 \
  --nic-name MyNic-Vm1 \
  --lb-name MyLoadBalancer \
  --lb-address-pools BeContoso
az network nic ip-config create \
  --resource-group $RgName \
  --name ipconfig3 \
  --nic-name MyNic-Vm1 \
  --lb-name MyLoadBalancer \
  --lb-address-pools BeFabrikam

# Create Vm1.
az vm create \
  --resource-group $RgName \
  --name MyVm1 \
  --nics MyNic-Vm1 \
  --image UbuntuLTS \
  --availability-set MyAvailabilitySet \
  --admin-username azureadmin \
  --generate-ssh-keys

############### VM2 ###############

# Create an Public IP for the second VM.
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIp-Vm2 \
  --allocation-method Dynamic

# Create a network interface for VM2.
az network nic create \
  --resource-group $RgName \
  --vnet-name MyVnet \
  --subnet MySubnet \
  --name MyNic-Vm2 \
  --public-ip-address MyPublicIp-Vm2

# Create IP-Configs for Contoso and Fabrikam.
az network nic ip-config create \
  --resource-group $RgName \
  --name ipconfig2 \
  --nic-name MyNic-Vm2 \
  --lb-name MyLoadBalancer \
  --lb-address-pools BeContoso
az network nic ip-config create \
  --resource-group $RgName \
  --name ipconfig3 \
  --nic-name MyNic-Vm2 \
  --lb-name MyLoadBalancer \
  --lb-address-pools BeFabrikam

# Create Vm2.
az vm create \
  --resource-group $RgName \
  --name MyVm2 \
  --nics MyNic-Vm2 \
  --image UbuntuLTS \
  --availability-set MyAvailabilitySet \
  --admin-username azureadmin \
  --generate-ssh-keys
