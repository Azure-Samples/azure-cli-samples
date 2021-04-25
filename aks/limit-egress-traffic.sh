## Background

## Required outbound network rules and FQDNs for AKS clusters

## Optional recommended FQDN / application rules for AKS clusters

## GPU enabled AKS clusters

## Windows Server based node pools 

## AKS addons and integrations

## Restrict egress traffic using Azure firewall

# Create Resource Group
az network public-ip create -g $RG -n $FWPUBLICIP_NAME -l $LOC --sku "Standard"
# Install Azure Firewall preview CLI extension
# Configure Firewall IP Config
# Create UDR and add a route for Azure Firewall
# Associate route table with next hop to Firewall to the AKS subnet
# Create SP and Assign Permission to Virtual Network
APPID="<SERVICE_PRINCIPAL_APPID_GOES_HERE>"
PASSWORD="<SERVICEPRINCIPAL_PASSWORD_GOES_HERE>"
VNETID=$(az network vnet show -g $RG --name $VNET_NAME --query id -o tsv)
SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)
az aks create -g $RG -n $AKSNAME -l $LOC \
  --node-count 3 --generate-ssh-keys \
  --network-plugin $PLUGIN \
  --outbound-type userDefinedRouting \
  --service-cidr 10.41.0.0/16 \
  --dns-service-ip 10.41.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id $SUBNETID \
  --service-principal $APPID \
  --client-secret $PASSWORD \
  --api-server-authorized-ip-ranges $FWPUBLIC_IP
az network firewall nat-rule create --collection-name exampleset --destination-addresses $FWPUBLIC_IP --destination-ports 80 --firewall-name $FWNAME --name inboundrule --protocols Any --resource-group $RG --source-addresses '*' --translated-port 80 --action Dnat --priority 100 --translated-address $SERVICE_IP
az group delete -g $RG
## Next steps
