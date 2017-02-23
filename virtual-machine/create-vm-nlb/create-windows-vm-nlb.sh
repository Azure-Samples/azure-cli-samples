#!/bin/bash

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a virtual network.
az network vnet create --resource-group myResourceGroup --location westus --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24

# Create a public IP address and specify a DNS name.
az network public-ip create --resource-group myResourceGroup --location westus \
  --name myPublicIP --dns-name mypublicdns$RANDOM --allocation-method static --idle-timeout 4

# Create an Azure Network Load Balancer.
az network lb create --resource-group myResourceGroup --location westus \
  --name myLoadBalancer --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool

# Creates an NLB probe on port 80.
az network lb probe create --resource-group myResourceGroup --lb-name myLoadBalancer \
  --name myHealthProbe --protocol tcp --port 80 --interval 15 --threshold 4

# Creates an NLB rule for port 80.
az network lb rule create --resource-group myResourceGroup --lb-name myLoadBalancer \
  --name myLoadBalancerRuleWeb --protocol tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool \
  --probe-name myHealthProbe

# Create three NAT rules for port 22.
for i in `seq 1 3`; do
  az network lb inbound-nat-rule create --resource-group myResourceGroup \
    --lb-name myLoadBalancer --name myLoadBalancerRuleRDP$i --protocol tcp \
    --frontend-port 3389$i --backend-port 3389 --frontend-ip-name myFrontEndPool
done

# Create a network security group
az network nsg create --resource-group myResourceGroup --location westus \
  --name myNetworkSecurityGroup

# Create a network security group rule for port 22.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleRDP \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 \
  --access allow

# Create a network security group rule for port 80.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleHTTP \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 \
  --access allow

# Create three virtual network cards and associate with public IP address and NSG.
for i in `seq 1 3`; do
  az network nic create --resource-group myResourceGroup --location westus --name myNic$i \
    --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup \
    --lb-name myLoadBalancer --lb-address-pools myBackEndPool \
    --lb-inbound-nat-rules myLoadBalancerRuleSSH$i
done

# Create an availability set.
az vm availability-set create --resource-group myResourceGroup --location westus \
  --name myAvailabilitySet --platform-fault-domain-count 3

# Create three virtual machines.
for i in `seq 1 3`; do
  az vm create \
    --resource-group myResourceGroup \
    --name myVM$i \
    --location westus \
    --availability-set myAvailabilitySet \
    --nics myNic$i \
    --image win2016datacenter \
    --admin-password $AdminPassword \
    --admin-username azureuser \
    --no-wait
done
