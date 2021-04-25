LOCATION=eastus
RESOURCE_GROUP=myResourceGroup
ADDRESS_PREFIXES=192.168.0.0/16
SUBNET_NAME=myAKSSubnet
SUBNET_PREFIX=192.168.1.0/24
VNET_NAME=myAKSVnet
ASSIGNEE=<appId>
ROLE="Network Contributor"
NODE_COUNT=3
NETWORK_PLUGIN=kubenet
SERVICE_CIDR=10.0.0.0/16
DNS_SERVICE_IP=10.0.0.10
POD_CIDR=10.244.0.0/16
DOCKER_BRIDGE_ADDRESS=172.17.0.1/16
SERVICE_PRINCIPAL=<appId>
CLIENT_SECRET=<password>
NETWORK_POLICY=calico
G=MyResourceGroup
N=MyManagedCluster
## Prerequisites

## Before you begin

## Overview of kubenet networking with your own subnet

## Create a virtual network and subnet

az group create --name myResourceGroup --location $LOCATION
az network vnet create --resource-group $RESOURCE_GROUP --name myAKSVnet --address-prefixes $ADDRESS_PREFIXES --subnet-name $SUBNET_NAME --subnet-prefix $SUBNET_PREFIX
## Create a service principal and assign permissions

az ad sp create-for-rbac
VNET_ID=$(az network vnet show --resource-group myResourceGroup --name myAKSVnet --query id -o tsv)
SUBNET_ID=$(az network vnet subnet show --resource-group myResourceGroup --vnet-name myAKSVnet --name myAKSSubnet --query id -o tsv)
az role assignment create --assignee $ASSIGNEE --scope $VNET_ID --role $ROLE
## Create an AKS cluster in the virtual network

az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --node-count $NODE_COUNT --network-plugin $NETWORK_PLUGIN --service-cidr $SERVICE_CIDR --dns-service-ip $DNS_SERVICE_IP --pod-cidr $POD_CIDR --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --vnet-subnet-id $SUBNET_ID --service-principal $SERVICE_PRINCIPAL --client-secret $CLIENT_SECRET
az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --node-count $NODE_COUNT --network-plugin $NETWORK_PLUGIN --network-policy $NETWORK_POLICY --service-cidr $SERVICE_CIDR --dns-service-ip $DNS_SERVICE_IP --pod-cidr $POD_CIDR --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --vnet-subnet-id $SUBNET_ID --service-principal $SERVICE_PRINCIPAL --client-secret $CLIENT_SECRET
## Bring your own subnet and route table with kubenet

# Find your subnet ID
az network vnet subnet list
                            --vnet-name
                            [--subscription]
# Create a kubernetes cluster with with a custom subnet preconfigured with a route table
az aks create -g $G -n $N --vnet-subnet-id MySubnetID
## Next steps
