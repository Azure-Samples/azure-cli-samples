#!/bin/bash
# Passed validation in Cloud Shell on 3/3/2022

# Load balance multiple websites

# Variable block for load balancer
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-load-balancer-rg-$randomIdentifier"
tags="load-balance-multiple-web-sites-vm"
availabilitySet="msdocs-availablity-set-lb-$randomIdentifier"
vNet="msdocs-vnet-lb-$randomIdentifier"
subnet="msdocs-subnet-lb-$randomIdentifier"
loadBalancerPublicIp="msdocs-public-ip-$randomIdentifier"
loadBalancerFrontEndConfig1="msdocs-contoso-$randomIdentifier"
loadBalancerFrontEndConfig2="msdocs-fabrikam-$randomIdentifier"
loadBalancer="msdocs-load-balancer-$randomIdentifier"
frontEndIpConfig1="msdocs-front-end-ip-config-contoso-$randomIdentifier"
frontEndIpConfig2="msdocs-front-end-ip-config-fabrikam-$randomIdentifier"
backEndAddressPool1="msdocs-back-end-address-pool-contoso-$randomIdentifier"
backEndAddressPool2="msdocs-back-end-address-pool-fabrikam-$randomIdentifier"
probe80="msdocs-port80-probe"
lbRuleConfig1="msdocs-contoso-load-balancer-rule-$randomIdentifier"
lbRuleConfig2="msdocs-fabrikam-load-balancer-rule-$randomIdentifier"
publicIpVm1="msdocs-public-ip-vm1-$randomIdentifier"
nicVm1="msdocs-nic-vm1-$randomIdentifier"
ipConfig1="msdocs-ipconfig-config1-$randomIdentifier"
ipConfig2="msdocs-ipconfig-config2-$randomIdentifier"
vm1="msdocs-vm1-$randomIdentifier"
publicIpVm2="msdocs-public-ip-vm2-$randomIdentifier"
ipSku="Standard"
nicVm2="msdocs-nic-vm2-$randomIdentifier"
ipConfig1="msdocs-ipconfig-config1-$randomIdentifier"
ipConfig2="msdocs-ipconfig-config2-$randomIdentifier"
vm2="msdocs-vm2-$randomIdentifier"
image="UbuntuLTS"
login="azureuser"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an availability set for the two VMs that host both websites.
echo "Creating $availabilitySet"
az vm availability-set create \
  --resource-group $resourceGroup \
  --location "$location" \
  --name $availabilitySet \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 2

# Create a virtual network and a subnet.
echo "Creating $vNet and $subnet"
az network vnet create \
  --resource-group $resourceGroup \
  --name $vNet \
  --address-prefix 10.0.0.0/16 \
  --location "$location" \
  --subnet-name $subnet \
  --subnet-prefix 10.0.0.0/24

# Create three public IP addresses; one for the load balancer and two for the front-end IP configurations.
echo "Creating $loadBalancerPublicIp"
az network public-ip create \
  --resource-group $resourceGroup \
  --name $loadBalancerPublicIp \
  --allocation-method Dynamic

echo "Creating $loadBalancerFrontEndConfig1"  
az network public-ip create \
  --resource-group $resourceGroup \
  --name $loadBalancerFrontEndConfig1 \
  --allocation-method Dynamic

echo "Creating $loadBalancerFrontEndConfig2"
az network public-ip create \
  --resource-group $resourceGroup \
  --name $loadBalancerFrontEndConfig2 \
  --allocation-method Dynamic

# Create a load balancer.
echo "Creating $loadBalancer"
az network lb create \
  --resource-group $resourceGroup \
  --location "$location" \
  --name $loadBalancer \
  --frontend-ip-name FrontEnd \
  --backend-pool-name BackEnd \
  --public-ip-address $loadBalancerPublicIp

# Create two front-end IP configurations for both web sites.
echo "Creating $frontEndIpConfig1 for $loadBalancerFrontEndConfig1"
az network lb frontend-ip create \
  --resource-group $resourceGroup \
  --lb-name $loadBalancer \
  --public-ip-address $loadBalancerFrontEndConfig1 \
  --name $frontEndIpConfig1

echo "Creating $frontEndIpConfig2 for $loadBalancerFrontEndConfig2"  
az network lb frontend-ip create \
  --resource-group $resourceGroup \
  --lb-name $loadBalancer \
  --public-ip-address $loadBalancerFrontEndConfig2 \
  --name $frontEndIpConfig2

# Create the back-end address pools.
echo "Creating $backEndAddressPool1"
az network lb address-pool create \
  --resource-group $resourceGroup \
  --lb-name $loadBalancer \
  --name $backEndAddressPool1

echo "Creating $backEndAddressPool2"
az network lb address-pool create \
  --resource-group $resourceGroup \
  --lb-name $loadBalancer \
  --name $backEndAddressPool2

# Create a probe on port 80.
echo "Creating $probe80 in $loadBalancer"
az network lb probe create \
  --resource-group $resourceGroup \
  --lb-name $loadBalancer \
  --name $probe80 \
  --protocol Http \
  --port 80 --path /

# Create the load balancing rules.
echo "Creating $lbRuleConfig1 for $loadBalancer"
az network lb rule create \
  --resource-group $resourceGroup \
  --lb-name $loadBalancer \
  --name $lbRuleConfig1 \
  --protocol Tcp \
  --probe-name $probe80 \
  --frontend-port 5000 \
  --backend-port 5000 \
  --frontend-ip-name $frontEndIpConfig1 \
  --backend-pool-name $backEndAddressPool1

echo "Creating $lbRuleConfig2 for $loadBalancer"
az network lb rule create \
  --resource-group $resourceGroup \
  --lb-name $loadBalancer \
  --name $lbRuleConfig2 \
  --protocol Tcp \
  --probe-name $probe80 \
  --frontend-port 5000 \
  --backend-port 5000 \
  --frontend-ip-name $frontEndIpConfig2 \
  --backend-pool-name $backEndAddressPool2

# ############## VM1 ###############

# Create an Public IP for the first VM.
echo "Creating $publicIpVm1"
az network public-ip create \
  --resource-group $resourceGroup \
  --name $publicIpVm1 \
  --allocation-method Dynamic

# Create a network interface for VM1.
echo "Creating $nicVm1 in $vNet and $subnet"
az network nic create \
  --resource-group $resourceGroup \
  --vnet-name $vNet \
  --subnet $subnet \
  --name $nicVm1 \
  --public-ip-address $publicIpVm1

# Create IP configurations for Contoso and Fabrikam.
echo "Creating $ipConfig1 for $nicVm1"
az network nic ip-config create \
  --resource-group $resourceGroup \
  --name $ipConfig1 \
  --nic-name $nicVm1 \
  --lb-name $loadBalancer \
  --lb-address-pools $backEndAddressPool1

echo "Creating $ipConfig2 for $nicVm1"
az network nic ip-config create \
  --resource-group $resourceGroup \
  --name $ipConfig2 \
  --nic-name $nicVm1 \
  --lb-name $loadBalancer \
  --lb-address-pools $backEndAddressPool2

# Create Vm1.
echo "Creating $vm1"
az vm create \
  --resource-group $resourceGroup \
  --name $vm1 \
  --nics $nicVm1 \
  --image $image \
  --availability-set $availabilitySet \
  --public-ip-sku $ipSku \
  --admin-username $login \
  --generate-ssh-keys

############### VM2 ###############

# Create an Public IP for the second VM.
echo "Creating $publicIpVm2"
az network public-ip create \
  --resource-group $resourceGroup \
  --name $publicIpVm2 \
  --allocation-method Dynamic

# Create a network interface for VM2.
echo "Creating $nicVm2 in $vNet and $subnet"
az network nic create \
  --resource-group $resourceGroup \
  --vnet-name $vNet \
  --subnet $subnet \
  --name $nicVm2 \
  --public-ip-address $publicIpVm2

# Create IP-Configs for Contoso and Fabrikam.
echo "Creating $ipConfig1 for $nicVm2"
az network nic ip-config create \
  --resource-group $resourceGroup \
  --name $ipConfig1 \
  --nic-name $nicVm2 \
  --lb-name $loadBalancer \
  --lb-address-pools $backEndAddressPool1

echo "Creating $ipConfig2 for $nicVm2"
az network nic ip-config create \
  --resource-group $resourceGroup \
  --name $ipConfig2 \
  --nic-name $nicVm2 \
  --lb-name $loadBalancer \
  --lb-address-pools $backEndAddressPool2

# Create Vm2.
echo "Creating $vm2"
az vm create \
  --resource-group $resourceGroup \
  --name $vm2 \
  --nics $nicVm2 \
  --image UbuntuLTS \
  --availability-set $availabilitySet \
  --public-ip-sku $ipSku \
  --admin-username $login \
  --generate-ssh-keys


# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
