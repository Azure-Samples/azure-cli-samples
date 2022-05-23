#!/bin/bash
# Passed validation in Cloud Shell 02/03/2022

# <FullScript>
# Use IPv6 for vNet with basic SKU

# IMPORTANT
# To use the IPv6 for Azure virtual network feature,
# you must configure your subscription only once as follows:
#
# az feature register --name AllowIPv6VirtualNetwork --namespace Microsoft.Network
# az feature register --name AllowIPv6CAOnStandardLB --namespace Microsoft.Network
#
# It takes up to 30 minutes for feature registration to complete. 
# You can check your registration status by running the following Azure CLI command:
#
# az feature show --name AllowIPv6VirtualNetwork --namespace Microsoft.Network
# az feature show --name AllowIPv6CAOnStandardLB --namespace Microsoft.Network
#
# After the registration is complete, run the following command:
#
# az provider register --namespace Microsoft.Network

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-virtual-network-rg-$randomIdentifier"
tag="virtual-network-cli-sample-ipv6-dual-stack"
ipV4PublicIp="msdocs-ipV4-public-ip-address-$randomIdentifier"
ipV6PublicIp="msdocs-ipV6-public-ip-address-$randomIdentifier"
ipV4RemoteAccessVm0="msdocs-ipV4-pubic-ip-for-vm0-remote-access-$randomIdentifier"
ipV4RemoteAccessVm1="msdocs-ipV4-pubic-ip-for-vm1-remote-access-$randomIdentifier"
sku="BASIC"
allocationMethod="dynamic"
loadBalancer="msdocs-load-balancer-$randomIdentifier"
lbFrontEndV4="msdocs-frontend-ip--$randomIdentifier"
lbPublicIpV4="msdocs-public-ip-$randomIdentifier"
lbBackEndPoolV4="msdocs-backend-pool-$randomIdentifier"
loadBalancerFrontEnd_v6="msdocs-load-balancer-frontend-ip-v6-$randomIdentifier"
loadBalancerBackEndPool_v6="msdocs-load-balancer-backend-pool-v6-$randomIdentifier"
loadBalancerRule_v4="msdocs-lb-rule-v4-$randomIdentifier"
loadBalancerRule_v6="msdocs-lb-rule-v6-$randomIdentifier"
availabilitySet="msdocs-availability-set-$randomIdentifier"
nsg="msdocs-network-security-group-$randomIdentifier"
vNet="msdocs-virtual-network-$randomIdentifier"
vNetAddressPrefixes="10.0.0.0/16 fd00:db8:deca::/48"
subnet="msdocs-single-dual-stack-subnet-$randomIdentifier"
subnetAddressPrefixes="10.0.0.0/24 fd00:db8:deca:deed::/64"
nic0="msdocs-nic0-$randomIdentifier"
nic1="msdocs-nic1-$randomIdentifier"
nic0ConfigIpV6="msdocs-ipV6-config-nic0-$randomIdentifier"
nic1ConfigIpV6="msdocs-ipV6-config-nic1-$randomIdentifier"
vm0="docvm0$randomIdentifier"
vm1="docvm1$randomIdentifier"
image="MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest"
vmSize="Standard_A2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an IPV4 IP address
echo "Creating $ipV4PublicIp"
az network public-ip create --name $ipV4PublicIp --resource-group $resourceGroup --location "$location" --sku $sku --allocation-method $allocationMethod --version IPv4

# Create an IPV6 IP address
echo "Creating $ipV6PublicIp"
az network public-ip create --name $ipV6PublicIp --resource-group $resourceGroup --location "$location" --sku $sku --allocation-method $allocationMethod --version IPv6

# Create public IP addresses for remote access to VMs
echo "Creating $ipV4RemoteAccessVm0 and $ipV4RemoteAccessVm1"
az network public-ip create --name $ipV4RemoteAccessVm0 --resource-group $resourceGroup --location "$location" --sku $sku --allocation-method $allocationMethod --version IPv4
az network public-ip create --name $ipV4RemoteAccessVm1 --resource-group $resourceGroup --location "$location" --sku $sku --allocation-method $allocationMethod --version IPv4

# Create load balancer
echo "Creating $loadBalancer"
az network lb create --name $loadBalancer --resource-group $resourceGroup --sku $sku --location "$location" --frontend-ip-name $lbFrontEndV4 --public-ip-address $lbPublicIpV4 --backend-pool-name $lbBackEndPoolV4

# Create IPv6 front-end
echo "Creating $ipV6PublicIp"
az network lb frontend-ip create --lb-name $loadBalancer --name $loadBalancerFrontEnd_v6 --resource-group $resourceGroup --public-ip-address $ipV6PublicIp

# Configure IPv6 back-end address pool
echo "Creating $loadBalancerBackEndPool_v6"
az network lb address-pool create --lb-name $loadBalancer --name $loadBalancerBackEndPool_v6 --resource-group $resourceGroup

# Create a load balancer rules
echo "Creating $loadBalancerRule_v4"
az network lb rule create --lb-name $loadBalancer --name $loadBalancerRule_v4 --resource-group $resourceGroup --frontend-ip-name $lbFrontEndV4 --protocol Tcp --frontend-port 80 --backend-port 80 --backend-pool-name $lbBackEndPoolV4
az network lb rule create --lb-name $loadBalancer --name $loadBalancerRule_v6 --resource-group $resourceGroup --frontend-ip-name $loadBalancerFrontEnd_v6 --protocol Tcp --frontend-port 80 --backend-port 80 --backend-pool-name $loadBalancerBackEndPool_v6

# Create an availability set
echo "Creating $availabilitySet"
az vm availability-set create --name $availabilitySet --resource-group $resourceGroup --location "$location" --platform-fault-domain-count 2 --platform-update-domain-count 2

# Create network security group
echo "Creating $nsg"
az network nsg create --name $nsg --resource-group $resourceGroup --location "$location"

# Create inbound rule for port 3389
echo "Creating inbound rule in $nsg for port 3389"
az network nsg rule create --name allowRdpIn --nsg-name $nsg --resource-group $resourceGroup --priority 100 --description "Allow Remote Desktop In" --access Allow --protocol "*" --direction Inbound --source-address-prefixes "*" --source-port-ranges 3389 --destination-address-prefixes "*" --destination-port-ranges 3389

# Create outbound rule
echo "Creating outbound rule in $nsg to allow all"
az network nsg rule create --name allowAllOut --nsg-name $nsg --resource-group $resourceGroup --priority 100 --description "Allow All Out" --access Allow --protocol "*" --direction Outbound --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "*"

# Create the virtual network with IPv4 and IPv6 addresses
echo "Creating $vNet"
az network vnet create --name $vNet --resource-group $resourceGroup --location "$location" --address-prefixes $vNetAddressPrefixes

# Create a single dual stack subnet with IPv4 and IPv6 addresses
echo "Creating $subnet"
az network vnet subnet create --name $subnet --resource-group $resourceGroup --vnet-name $vNet --address-prefixes $subnetAddressPrefixes --network-security-group $nsg

# Create NICs
echo "Creating $nic0 and $nic1"
az network nic create --name $nic0 --resource-group $resourceGroup --network-security-group $nsg --vnet-name $vNet --subnet $subnet --private-ip-address-version IPv4 --lb-address-pools $lbBackEndPoolV4 --lb-name $loadBalancer --public-ip-address $ipV4RemoteAccessVm1
az network nic create --name $nic1 --resource-group $resourceGroup --network-security-group $nsg --vnet-name $vNet --subnet $subnet --private-ip-address-version IPv4 --lb-address-pools $lbBackEndPoolV4 --lb-name $loadBalancer --public-ip-address $ipV4RemoteAccessVm0

# Create IPV6 configurations for each NIC
echo "Creating $nic0ConfigIpV6 and $nic1ConfigIpV6"
az network nic ip-config create --name $nic0ConfigIpV6 --nic-name $nic0 --resource-group $resourceGroup --vnet-name $vNet --subnet $subnet --private-ip-address-version IPv6 --lb-address-pools $loadBalancerBackEndPool_v6 --lb-name $loadBalancer
az network nic ip-config create --name $nic1ConfigIpV6 --nic-name $nic1 --resource-group $resourceGroup --vnet-name $vNet --subnet $subnet --private-ip-address-version IPv6 --lb-address-pools $loadBalancerBackEndPool_v6 --lb-name $loadBalancer

# Create virtual machines
Creating "$vm0 and $vm1"
az vm create --name $vm0 --resource-group $resourceGroup --nics $nic0 --size $vmSize --availability-set $availabilitySet --image $image --public-ip-sku $sku --admin-user $login --admin-password $password
az vm create --name $vm1 --resource-group $resourceGroup --nics $nic1 --size $vmSize --availability-set $availabilitySet --image $image --public-ip-sku $sku --admin-user $login --admin-password $password
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
