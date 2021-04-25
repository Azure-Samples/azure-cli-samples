NAMESPACE=Microsoft.ContainerInstance
LOCATION=westus
RESOURCE_GROUP=myResourceGroup
SUBNET_PREFIX=10.240.0.0/16
VNET_NAME=myVnet
ASSIGNEE=<appId>
SCOPE=<vnetId>
ROLE=Contributor
NODE_COUNT=1
NETWORK_PLUGIN=azure
SERVICE_CIDR=10.0.0.0/16
DNS_SERVICE_IP=10.0.0.10
DOCKER_BRIDGE_ADDRESS=172.17.0.1/16
VNET_SUBNET_ID=<subnetId>
SERVICE_PRINCIPAL=<appId>
CLIENT_SECRET=<password>
ADDONS=virtual-node
## Before you begin

az provider list --query "[?contains(namespace,'Microsoft.ContainerInstance')]" -o table
az provider register --namespace $NAMESPACE
## Launch Azure Cloud Shell

## Create a resource group

az group create --name myResourceGroup --location $LOCATION
## Create a virtual network

az network vnet create --resource-group $RESOURCE_GROUP --name myVnet --address-prefixes 10.0.0.0/8 --subnet-name myAKSSubnet --subnet-prefix $SUBNET_PREFIX
az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name myVirtualNodeSubnet --address-prefixes 10.241.0.0/16
## Create a service principal or use a managed identity

az ad sp create-for-rbac
## Assign permissions to the virtual network

az network vnet show --resource-group $RESOURCE_GROUP --name myVnet --query id -o tsv
az role assignment create --assignee $ASSIGNEE --scope $SCOPE --role $ROLE
## Create an AKS cluster

az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name myAKSSubnet --query id -o tsv
az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --node-count $NODE_COUNT --network-plugin $NETWORK_PLUGIN --service-cidr $SERVICE_CIDR --dns-service-ip $DNS_SERVICE_IP --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --vnet-subnet-id $VNET_SUBNET_ID --service-principal $SERVICE_PRINCIPAL --client-secret $CLIENT_SECRET
## Enable virtual nodes addon

az aks enable-addons --resource-group $RESOURCE_GROUP --name myAKSCluster --addons $ADDONS --subnet-name myVirtualNodeSubnet
## Connect to the cluster

az aks get-credentials --resource-group $RESOURCE_GROUP --name myAKSCluster
## Deploy a sample app

## Test the virtual node pod

## Remove virtual nodes

az aks disable-addons --resource-group $RESOURCE_GROUP --name myAKSCluster --addons $ADDONS
# Change the name of your resource group, cluster and network resources as needed
RES_GROUP=myResourceGroup
AKS_CLUSTER=myAKScluster
AKS_VNET=myVnet
AKS_SUBNET=myVirtualNodeSubnet
## Next steps
