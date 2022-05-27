#/bin/bash
# Passed validation in Cloud Shell on 4/30/2022
# Code blocks for ../container-instances/container-instances-egress-ip-address.md
# <FullScript>
# Configure a single public IP address for outbound and inbound traffic to a container group
# set -e # exit if error
# Variable block
# <variable>
resourceGroup=resourceGroup$RANDOM
# </variable>
# <creategroup>
az group create --name $resourceGroup --location eastus
# </creategroup>
# <container>
az container create \
  --name appcontainer \
  --resource-group $resourceGroup \
  --image mcr.microsoft.com/azuredocs/aci-helloworld \
  --vnet aci-vnet \
  --vnet-address-prefix 10.0.0.0/16 \
  --subnet aci-subnet \
  --subnet-address-prefix 10.0.0.0/24
# </container>
# <privateip>
aciPrivateIp="$(az container show --name appcontainer \
  --resource-group $resourceGroup \
  --query ipAddress.ip --output tsv)"
# </privateip>
# <subnet>
az network vnet subnet create \
  --name AzureFirewallSubnet \
  --resource-group $resourceGroup \
  --vnet-name aci-vnet   \
  --address-prefix 10.0.1.0/26
# </subnet>
# <firewallext>
az extension add --name azure-firewall
# </firewallext>
# <firewall>
az network firewall create \
  --name myFirewall \
  --resource-group $resourceGroup \
  --location eastus

az network public-ip create \
  --name fw-pip \
  --resource-group $resourceGroup \
  --location eastus \
  --allocation-method static \
  --sku standard
    
az network firewall ip-config create \
  --firewall-name myFirewall \
  --name FW-config \
  --public-ip-address fw-pip \
  --resource-group $resourceGroup \
  --vnet-name aci-vnet
# </firewall>
# <firewallupdate>
az network firewall update \
  --name myFirewall \
  --resource-group $resourceGroup
# </firewallupdate>
# <storeprivateip>
fwPrivateIp="$(az network firewall ip-config list \
  --resource-group $resourceGroup \
  --firewall-name myFirewall \
  --query "[].privateIpAddress" --output tsv)"
# </storeprivateip>
# <storepublicip>
fwPublicIp="$(az network public-ip show \
  --name fw-pip \
  --resource-group $resourceGroup \
  --query ipAddress --output tsv)"
# </storepublicip>
# <routetable>
az network route-table create \
  --name Firewall-rt-table \
  --resource-group $resourceGroup \
  --location eastus \
  --disable-bgp-route-propagation true
# </routetable>
# <createroute>
az network route-table route create \
  --resource-group $resourceGroup \
  --name DG-Route \
  --route-table-name Firewall-rt-table \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $fwPrivateIp
# </createroute>
# <associateroute>
az network vnet subnet update \
  --name aci-subnet \
  --resource-group $resourceGroup \
  --vnet-name aci-vnet \
  --address-prefixes 10.0.0.0/24 \
  --route-table Firewall-rt-table
# </associateroute>
# <natrule>
az network firewall nat-rule create \
  --firewall-name myFirewall \
  --collection-name myNATCollection \
  --action dnat \
  --name myRule \
  --protocols TCP \
  --source-addresses '*' \
  --destination-addresses $fwPublicIp \
  --destination-ports 80 \
  --resource-group $resourceGroup \
  --translated-address $aciPrivateIp \
  --translated-port 80 \
  --priority 200
# </natrule>
# <outboundrule>
az network firewall application-rule create \
  --collection-name myAppCollection \
  --firewall-name myFirewall \
  --name Allow-CheckIP \
  --protocols Http=80 Https=443 \
  --resource-group $resourceGroup \
  --target-fqdns checkip.dyndns.org \
  --source-addresses 10.0.0.0/24 \
  --priority 200 \
  --action Allow
# </outboundrule>
# <echo>
echo $fwPublicIp
# </echo>
# <egress>
az container create \
  --resource-group $resourceGroup \
  --name testegress \
  --image mcr.microsoft.com/azuredocs/aci-tutorial-sidecar \
  --command-line "curl -s http://checkip.dyndns.org" \
  --restart-policy OnFailure \
  --vnet aci-vnet \
  --subnet aci-subnet
# </egress>
# <viewlogs>
az container logs \
  --resource-group $resourceGroup \
  --name testegress
# </viewlogs>
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
