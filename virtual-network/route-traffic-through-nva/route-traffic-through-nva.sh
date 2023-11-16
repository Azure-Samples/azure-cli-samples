#!/bin/bash
# Passed validation in Cloud Shell 02/03/2022

# <FullScript>
# Route traffic through NVA

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-virtual-network-rg-$randomIdentifier"
tag="route-traffic-through-nva-virtual-networks"
vNet="msdocs-vNet-$randomIdentifier"
addressPrefixVNet="10.0.0.0/16"
subnetFrontEnd="msdocs-frontend-subnet-$randomIdentifier"
subnetPrefixFrontEnd="10.0.1.0/24"
nsgFrontEnd="msdocs-nsg-frontend-$randomIdentifier"
subnetBackEnd="msdocs-backend-subnet-$randomIdentifier"
subnetPrefixBackEnd="10.0.2.0/24"
dmzSubnet="msdocs-dmz-$randomIdentifier"
dmzPrefix="10.0.0.0/24"
publicIpFirewall="msdocs-publicIpFirewall-$randomIdentifier"
nicFirewall="msdocs-nic-firewall-$randomIdentifier"
vmFirewall="msdocs-vm-$randomIdentifier"
sku="BASIC"
image="Ubuntu2204"
login="azureuser"
routeTableFrontEndSubnet="msdocs-route-table-frontend-subnet-$randomIdentifier"
routeToBackEnd="msdocs-route-backend-$randomIdentifier"
routeToInternetFrontEnd="msdocs-route-internet-frontend-$randomIdentifier"
routeToInternetPrefix="0.0.0.0/0"
routeTableBackEndSubnet="msdocs-route-table-backend-subnet-$randomIdentifier"
routeToFrontEnd="msdocs-route-frontend-$randomIdentifier"
routeToInternetBackEnd="msdocs-route-internet-backend-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network and a front-end subnet.
echo "Creating $vNet and $subnetFrontEnd"
az network vnet create --resource-group $resourceGroup --name $vNet --address-prefix $addressPrefixVNet  --location "$location" --subnet-name $subnetFrontEnd --subnet-prefix $subnetPrefixFrontEnd

# Create a network security group (NSG) for the front-end subnet.
echo "Creating $nsgFrontEnd for $subnetFrontEnd"
az network nsg create --resource-group $resourceGroup --name $nsgFrontEnd --location "$location"

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
echo "Creating NSG rules in $nsgFrontEnd to allow HTTP and HTTPS inbound traffic"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443

# Associate the front-end NSG to the front-end subnet.
echo "Associate $nsgFrontEnd to $subnetFrontEnd"
az network vnet subnet update --vnet-name $vNet --name $subnetFrontEnd --resource-group $resourceGroup --network-security-group $nsgFrontEnd

# Create a backend subnet.
echo "Creating $subnetBackEnd for $vNet"
az network vnet subnet create --address-prefix $subnetPrefixBackEnd --name $subnetBackEnd --resource-group $resourceGroup --vnet-name $vNet

#Create the DMZ subnet.
echo "Creating $dmzSubnet for $vNet"
az network vnet subnet create --address-prefix $dmzPrefix --name $dmzSubnet --resource-group $resourceGroup --vnet-name $vNet

# Create a public IP address for the firewall VM.
echo "Creating $publicIpFirewall"
az network public-ip create --resource-group $resourceGroup --name $publicIpFirewall

# Create a NIC for the firewall VM and enable IP forwarding.
echo "Creating $nicFirewall with IP forwarding"
az network nic create --resource-group $resourceGroup --name $nicFirewall --vnet-name $vNet --subnet $dmzSubnet --public-ip-address $publicIpFirewall --ip-forwarding

#Create a firewall VM to accept all traffic between the front and backend subnets.
echo "Creating $vmFirewall"
az vm create --resource-group $resourceGroup --name $vmFirewall --nics $nicFirewall --image $image --admin-username $login --generate-ssh-keys --public-ip-sku $sku

# Get the private IP address from the VM for the user-defined route.
echo "Get the private IP address from $vmFirewall"
Fw1Ip=$(az vm list-ip-addresses --resource-group $resourceGroup --name $vmFirewall --query [].virtualMachine.network.privateIpAddresses[0] --out tsv)

# Create route table for the FrontEnd subnet.
echo "Creating $routeTableFrontEndSubnet"
az network route-table create --name $routeTableFrontEndSubnet --resource-group $resourceGroup

# Create a route for traffic from the front-end to the backend subnet through the firewall VM.
echo "Creating $routeToBackEnd to $subnetPrefixBackEnd in $routeTableFrontEndSubnet"
az network route-table route create --name $routeToBackEnd --resource-group $resourceGroup --route-table-name $routeTableFrontEndSubnet --address-prefix $subnetPrefixBackEnd --next-hop-type VirtualAppliance --next-hop-ip-address $Fw1Ip
  
# Create a route for traffic from the front-end subnet to the Internet through the firewall VM.
echo "Creating route $routeToInternetFrontEnd to Internet in $routeTableFrontEndSubnet"
az network route-table route create --name $routeToInternetFrontEnd --resource-group $resourceGroup --route-table-name $routeTableFrontEndSubnet --address-prefix $routeToInternetPrefix --next-hop-type VirtualAppliance --next-hop-ip-address $Fw1Ip

# Associate the route table to the FrontEnd subnet.
echo "Associate $routeTableFrontEndSubnet to $subnetFrontEnd"
az network vnet subnet update --name $subnetFrontEnd --vnet-name $vNet --resource-group $resourceGroup --route-table $routeTableFrontEndSubnet

# Create route table for the BackEnd subnet.
echo "Creating $routeTableBackEndSubnet"
az network route-table create --name $routeTableBackEndSubnet --resource-group $resourceGroup

# Create a route for traffic from the backend subnet to the front-end subnet through the firewall VM.
echo "Creating $routeToFrontEnd to $subnetPrefixBackEnd in $routeTableBackEndSubnet"
az network route-table route create --name $routeToFrontEnd --resource-group $resourceGroup --route-table-name $routeTableBackEndSubnet --address-prefix $subnetPrefixBackEnd --next-hop-type VirtualAppliance --next-hop-ip-address $Fw1Ip

# Create a route for traffic from the backend subnet to the Internet through the firewall VM.
echo "Creating route $routeToInternetBackEnd to Internet in $routeTableBackEndSubnet"
az network route-table route create --name $routeToInternetBackEnd --resource-group $resourceGroup --route-table-name $routeTableBackEndSubnet --address-prefix $routeToInternetPrefix --next-hop-type VirtualAppliance --next-hop-ip-address $Fw1Ip

# Associate the route table to the BackEnd subnet.
echo "Associate $routeTableBackEndSubnet to $subnetBackEnd"
az network vnet subnet update --name $subnetBackEnd --vnet-name $vNet --resource-group $resourceGroup --route-table $routeTableBackEndSubnet
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
