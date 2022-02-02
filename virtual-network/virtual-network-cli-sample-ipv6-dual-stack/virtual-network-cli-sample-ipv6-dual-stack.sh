#!/bin/bash
# Passed validation in Cloud Shell 02/01/2022

# IMPORTANT
# To use the IPv6 for Azure virtual network feature, you must configure your subscription only once as follows:
# az feature register --name AllowIPv6VirtualNetwork --namespace Microsoft.Network
# az feature register --name AllowIPv6CAOnStandardLB --namespace Microsoft.Network
# It takes up to 30 minutes for feature registration to complete. You can check your registration status by running the following Azure CLI command:
# az feature show --name AllowIPv6VirtualNetwork --namespace Microsoft.Network
# az feature show --name AllowIPv6CAOnStandardLB --namespace Microsoft.Network
# After the registration is complete, run the following command:
# az provider register --namespace Microsoft.Network

let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="virtual-network-cli-sample-ipv6-dual-stack-$randomIdentifier"
ipV4PublicIp="msdocs-ipV4-public-ip-address-$randomIdentifier"
ipV6PublicIp="msdocs-ipV6-public-ip-address-$randomIdentifier"
ipV4RemoteAccessVm0="msdocs-ipV4-pubic-ip-for-vm0-remote-access-$randomIdentifier"
ipV4RemoteAccessVm1="msdocs-ipV4-pubic-ip-for-vm1-remote-access-$randomIdentifier"
sku="BASIC"
loadBalancer="msdocs-load-balances-$randomIdentifier"


# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an IPV4 IP address
echo "Creating $ipV4PublicIp"
az network public-ip create --name $ipV4PublicIp  --resource-group $resourceGroup  --location "$location"  --sku $sku  --allocation-method dynamic  --version IPv4

# Create an IPV6 IP address
echo "Creating $ipV6PublicIp"
az network public-ip create --name $ipV6PublicIp  --resource-group $resourceGroup  --location "$location" --sku $sku  --allocation-method dynamic  --version IPv6

# Create public IP addresses for remote access to VMs
echo "Creating $ipV4RemoteAccessVm0 and $ipV4RemoteAccessVm1"
az network public-ip create --name $ipV4RemoteAccessVm0 --resource-group $resourceGroup--loca tion "$location" --sku $sku --allocation-method dynamic --version IPv4
az network public-ip create --name $ipV4RemoteAccessVm1 --resource-group $resourceGroup --location "$location" --sku $sku --allocation-method dynamic --version IPv4

# Create load balancer
echo "Creating $loadBalancer"
az network lb create \
--name $loadBalancer  \
--resource-group $resourceGroup \
--sku $sku \
--location "$location" \
--frontend-ip-name dsLbFrontEnd_v4  \
--public-ip-address dsPublicIP_v4  \
--backend-pool-name dsLbBackEndPool_v4

# Create IPv6 front-end
az network lb frontend-ip create \
--lb-name dsLB  \
--name dsLbFrontEnd_v6  \
--resource-group DsResourceGroup01  \
--public-ip-address dsPublicIP_v6

# Configure IPv6 back-end address pool
az network lb address-pool create \
--lb-name dsLB  \
--name dsLbBackEndPool_v6  \
--resource-group DsResourceGroup01

# Create a load balancer rule

az network lb rule create \
--lb-name dsLB  \
--name dsLBrule_v4  \
--resource-group DsResourceGroup01  \
--frontend-ip-name dsLbFrontEnd_v4  \
--protocol Tcp  \
--frontend-port 80  \
--backend-port 80  \
--backend-pool-name dsLbBackEndPool_v4


az network lb rule create 
--lb-name dsLB  \
--name dsLBrule_v6  \
--resource-group DsResourceGroup01 \
--frontend-ip-name dsLbFrontEnd_v6  \
--protocol Tcp  \
--frontend-port 80 \
--backend-port 80  \
--backend-pool-name dsLbBackEndPool_v6

# Create an availability set
az vm availability-set create \
--name dsAVset  \
--resource-group DsResourceGroup01  \
--location eastus \
--platform-fault-domain-count 2  \
--platform-update-domain-count 2

# Create network security group

az network nsg create \
--name dsNSG1  \
--resource-group DsResourceGroup01  \
--location eastus

# Create inbound rule for port 3389
az network nsg rule create \
--name allowRdpIn  \
--nsg-name dsNSG1  \
--resource-group DsResourceGroup01  \
--priority 100  \
--description "Allow Remote Desktop In"  \
--access Allow  \
--protocol "*"  \
--direction Inbound  \
--source-address-prefixes "*"  \
--source-port-ranges 3389  \
--destination-address-prefixes "*"  \
--destination-port-ranges 3389

# Create outbound rule

az network nsg rule create \
--name allowAllOut  \
--nsg-name dsNSG1  \
--resource-group DsResourceGroup01  \
--priority 100  \
--description "Allow All Out"  \
--access Allow  \
--protocol "*"  \
--direction Outbound  \
--source-address-prefixes "*"  \
--source-port-ranges "*"  \
--destination-address-prefixes "*"  \
--destination-port-ranges "*"

# Create the virtual network
az network vnet create \
--name dsVNET \
--resource-group DsResourceGroup01 \
--location eastus  \
--address-prefixes "10.0.0.0/16" "fd00:db8:deca::/48"

# Create a single dual stack subnet

az network vnet subnet create \
--name dsSubNET \
--resource-group DsResourceGroup01 \
--vnet-name dsVNET \
--address-prefix 10.0.0.0/24 \
--address-prefix "fd00:db8:deca:deed::/64" \
--network-security-group dsNSG1

# Create NICs
az network nic create \
--name dsNIC0  \
--resource-group DsResourceGroup01 \
--network-security-group dsNSG1  \
--vnet-name dsVNET  \
--subnet dsSubNet  \
--private-ip-address-version IPv4 \
--lb-address-pools dsLbBackEndPool_v4  \
--lb-name dsLB  \
--public-ip-address dsVM0_remote_access

az network nic create \
--name dsNIC1 \
--resource-group DsResourceGroup01 \
--network-security-group dsNSG1 \
--vnet-name dsVNET \
--subnet dsSubNet \
--private-ip-address-version IPv4 \
--lb-address-pools dsLbBackEndPool_v4 \
--lb-name dsLB \
--public-ip-address dsVM1_remote_access

# Create IPV6 configurations for each NIC

az network nic ip-config create \
--name dsIp6Config_NIC0  \
--nic-name dsNIC0  \
--resource-group DsResourceGroup01 \
--vnet-name dsVNET \
--subnet dsSubNet \
--private-ip-address-version IPv6 \
--lb-address-pools dsLbBackEndPool_v6 \
--lb-name dsLB

az network nic ip-config create \
--name dsIp6Config_NIC1 \
--nic-name dsNIC1 \
--resource-group DsResourceGroup01 \
--vnet-name dsVNET \
--subnet dsSubNet \
--private-ip-address-version IPv6 \
--lb-address-pools dsLbBackEndPool_v6 
--lb-name dsLB

# Create virtual machines
 az vm create \
--name dsVM0 \
--resource-group DsResourceGroup01 \
--nics dsNIC0 \
--size Standard_A2 \
--availability-set dsAVset \
--image MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest  

az vm create \
--name dsVM1 \
--resource-group DsResourceGroup01 \
--nics dsNIC1 \
--size Standard_A2 \
--availability-set dsAVset \
--image MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest
