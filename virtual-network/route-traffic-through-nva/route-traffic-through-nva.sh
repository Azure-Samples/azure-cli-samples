#!/bin/bash

RgName="MyResourceGroup"
Location="westus"

# Create a resource group.
az group create \
  --name $RgName \
  --location $Location

# Create a virtual network with a front-end subnet.
az network vnet create \
  --name MyVnet \
  --resource-group $RgName \
  --location $Location \
  --address-prefix 10.0.0.0/16 \
  --subnet-name MySubnet-FrontEnd \
  --subnet-prefix 10.0.1.0/24

# Create a network security group for the front-end subnet allowing HTTP and HTTPS inbound.
az network nsg create \
  --resource-group $RgName \
  --name MyNsg-FrontEnd \
  --location $Location

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
az network nsg rule create \
  --resource-group $RgName \
  --nsg-name MyNsg-FrontEnd \
  --name Allow-HTTP-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 100 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 80
az network nsg rule create \
  --resource-group $RgName \
  --nsg-name MyNsg-FrontEnd \
  --name Allow-HTTPS-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 200 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 443

# Associate the front-end NSG to the front-end subnet.
az network vnet subnet update \
  --vnet-name MyVnet \
  --name MySubnet-FrontEnd \
  --resource-group $RgName \
  --network-security-group MyNsg-FrontEnd

# Create the back-end subnet.
az network vnet subnet create \
  --address-prefix 10.0.2.0/24 \
  --name MySubnet-BackEnd \
  --resource-group $RgName \
  --vnet-name MyVnet

#Create the DMZ subnet.
az network vnet subnet create \
  --address-prefix 10.0.0.0/24 \
  --name MySubnet-Dmz \
  --resource-group $RgName \
  --vnet-name MyVnet

# Create a public IP address for the firewall VM.
az network public-ip create \
  --resource-group $RgName \
  --name MyPublicIP-Firewall

# Create a NIC for the firewall VM and enable IP forwarding.
az network nic create \
  --resource-group $RgName \
  --name MyNic-Firewall \
  --vnet-name MyVnet \
  --subnet MySubnet-Dmz \
  --public-ip-address MyPublicIp-Firewall \
  --ip-forwarding

#Create a firewall VM to accept all traffic between the front and back-end subnets.
az vm create \
  --resource-group $RgName \
  --name MyVm-Firewall \
  --nics MyNic-Firewall \
  --image UbuntuLTS \
  --generate-ssh-keys

# Get the private IP address from the VM for the user-defined route.
Fw1Ip=$(az vm list-ip-addresses \
  --resource-group $RgName \
  --name MyVm-Firewall \
  --query [].virtualMachine.network.privateIpAddresses[0] --out tsv)

# Create route table for the FrontEnd subnet.
az network route-table create \
  --name MyRouteTable-FrontEnd \
  --resource-group $RgName

# Create a route for traffic from the front-end to the back-end subnet through the firewall VM.
az network route-table route create \
  --name RouteToBackEnd \
  --resource-group $RgName \
  --route-table-name MyRouteTable-FrontEnd \
  --address-prefix 10.0.2.0/24 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $Fw1Ip
  
# Create a route for traffic from the front-end subnet to the Internet through the firewall VM.
az network route-table route create \
  --name RouteToInternet \
  --resource-group $RgName \
  --route-table-name MyRouteTable-FrontEnd \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $Fw1Ip

# Associate the route table to the FrontEnd subnet.
az network vnet subnet update \
  --name MySubnet-FrontEnd \
  --vnet-name MyVnet \
  --resource-group $RgName \
  --route-table MyRouteTable-FrontEnd

# Create route table for the BackEnd subnet.
az network route-table create \
  --name MyRouteTable-BackEnd \
  --resource-group $RgName
  
# Create a route for traffic from the back-end subnet to the front-end subnet through the firewall VM.
az network route-table route create \
  --name RouteToFrontEnd \
  --resource-group $RgName \
  --route-table-name MyRouteTable-BackEnd \
  --address-prefix 10.0.1.0/24 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $Fw1Ip

# Create a route for traffic from the back-end subnet to the Internet through the firewall VM.
az network route-table route create \
  --name RouteToInternet \
  --resource-group $RgName \
  --route-table-name MyRouteTable-BackEnd \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $Fw1Ip

# Associate the route table to the BackEnd subnet.
az network vnet subnet update \
  --name MySubnet-BackEnd \
  --vnet-name MyVnet \
  --resource-group $RgName \
  --route-table MyRouteTable-BackEnd
