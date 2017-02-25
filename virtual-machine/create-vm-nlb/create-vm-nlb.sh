#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup6 --location westeurope

# Create a virtual network.
az network vnet create --resource-group myResourceGroup6 --location westeurope --name myVnet --subnet-name mySubnet

# Create a public IP address.
az network public-ip create --resource-group myResourceGroup6 --name myPublicIP

# Create an Azure Network Load Balancer.
az network lb create --resource-group myResourceGroup6 --location westeurope \
  --name myLoadBalancer --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool

# Creates an NLB probe on port 80.
az network lb probe create --resource-group myResourceGroup6 --lb-name myLoadBalancer \
  --name myHealthProbe --protocol tcp --port 80

# Creates an NLB rule for port 80.
az network lb rule create --resource-group myResourceGroup6 --lb-name myLoadBalancer \
  --name myLoadBalancerRuleWeb --protocol tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool \
  --probe-name myHealthProbe

# Create three NAT rules for port 22.
for i in `seq 1 3`; do
  az network lb inbound-nat-rule create --resource-group myResourceGroup6 \
    --lb-name myLoadBalancer --name myLoadBalancerRuleSSH$i --protocol tcp \
    --frontend-port 422$i --backend-port 22 --frontend-ip-name myFrontEndPool
done

# Create a network security group
az network nsg create --resource-group myResourceGroup6 --name myNetworkSecurityGroup

# Create a network security group rule for port 22.
az network nsg rule create --resource-group myResourceGroup6 \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleSSH \
  --protocol tcp --direction inbound --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

# Create a network security group rule for port 80.
az network nsg rule create --resource-group myResourceGroup6 \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleHTTP \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 \
  --access allow

# Create three virtual network cards and associate with public IP address and NSG.
for i in `seq 1 3`; do
  az network nic create --resource-group myResourceGroup6 --name myNic$i \
    --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup \
    --lb-name myLoadBalancer --lb-address-pools myBackEndPool \
    --lb-inbound-nat-rules myLoadBalancerRuleSSH$i
done

# Create an availability set.
az vm availability-set create --resource-group myResourceGroup6 \
  --name myAvailabilitySet --platform-fault-domain-count 3

# Create three virtual machines.
for i in `seq 1 3`; do
  az vm create \
    --resource-group myResourceGroup6 \
    --name myVM$i \
    --location westeurope \
    --availability-set myAvailabilitySet \
    --nics myNic$i \
    --image UbuntuLTS \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --admin-username azureuser \
    --no-wait
done