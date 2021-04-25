$RG=""
SKU="Standard"
$VNET_NAME=""
NODE_COUNT=3
GENERATE_SSH_KEYS= 
$PLUGIN  =""
OUTBOUND_TYPE=userDefinedRouting  
SERVICE_CIDR=10.41.0.0/16  
DNS_SERVICE_IP=10.41.0.10  
DOCKER_BRIDGE_ADDRESS=172.17.0.1/16  
$SUBNETID  =""
$APPID  =""
$PASSWORD  =""
$FWPUBLIC_IP=""
COLLECTION_NAME=exampleset
$FWPUBLIC_IP=""
DESTINATION_PORTS=80
$FWNAME=""
PROTOCOLS=Any
$RG=""
SOURCE_ADDRESSES='*'
TRANSLATED_PORT=80
ACTION=Dnat
PRIORITY=100
$SERVICE_IP=""
## Background

## Required outbound network rules and FQDNs for AKS clusters

## Optional recommended FQDN / application rules for AKS clusters

## GPU enabled AKS clusters

## Windows Server based node pools 

## AKS addons and integrations

## Restrict egress traffic using Azure firewall

# Create Resource Group
az network public-ip create -g $RG -n $FWPUBLICIP_NAME -l $LOC --sku $SKU
# Install Azure Firewall preview CLI extension
# Configure Firewall IP Config
# Create UDR and add a route for Azure Firewall
# Associate route table with next hop to Firewall to the AKS subnet
# Create SP and Assign Permission to Virtual Network
APPID="<SERVICE_PRINCIPAL_APPID_GOES_HERE>"
PASSWORD="<SERVICEPRINCIPAL_PASSWORD_GOES_HERE>"
VNETID=$(az network vnet show -g $RG --name $VNET_NAME --query id -o tsv)
SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)
az aks create -g $RG -n $AKSNAME -l $LOC   --node-count $NODE_COUNT --generate-ssh-keys $GENERATE_SSH_KEYS --network-plugin $PLUGIN   --outbound-type $OUTBOUND_TYPE --service-cidr $SERVICE_CIDR --dns-service-ip $DNS_SERVICE_IP --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --vnet-subnet-id $SUBNETID   --service-principal $APPID   --client-secret $PASSWORD   --api-server-authorized-ip-ranges $FWPUBLIC_IP
az network firewall nat-rule create --collection-name $COLLECTION_NAME --destination-addresses $FWPUBLIC_IP --destination-ports $DESTINATION_PORTS --firewall-name $FWNAME --name inboundrule --protocols $PROTOCOLS --resource-group $RG --source-addresses $SOURCE_ADDRESSES --translated-port $TRANSLATED_PORT --action $ACTION --priority $PRIORITY --translated-address $SERVICE_IP
az group delete -g $RG
## Next steps
