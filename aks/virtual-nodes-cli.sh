## Before you begin

az provider list --query "[?contains(namespace,'Microsoft.ContainerInstance')]" -o table
az provider register --namespace Microsoft.ContainerInstance
## Launch Azure Cloud Shell

## Create a resource group

az group create --name myResourceGroup --location westus
## Create a virtual network

az network vnet create \
    --resource-group myResourceGroup \
    --name myVnet \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name myAKSSubnet \
    --subnet-prefix 10.240.0.0/16
az network vnet subnet create \
    --resource-group myResourceGroup \
    --vnet-name myVnet \
    --name myVirtualNodeSubnet \
    --address-prefixes 10.241.0.0/16
## Create a service principal or use a managed identity

az ad sp create-for-rbac --skip-assignment
## Assign permissions to the virtual network

az network vnet show --resource-group myResourceGroup --name myVnet --query id -o tsv
az role assignment create --assignee <appId> --scope <vnetId> --role Contributor
## Create an AKS cluster

az network vnet subnet show --resource-group myResourceGroup --vnet-name myVnet --name myAKSSubnet --query id -o tsv
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 1 \
    --network-plugin azure \
    --service-cidr 10.0.0.0/16 \
    --dns-service-ip 10.0.0.10 \
    --docker-bridge-address 172.17.0.1/16 \
    --vnet-subnet-id <subnetId> \
    --service-principal <appId> \
    --client-secret <password>
## Enable virtual nodes addon

az aks enable-addons \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --addons virtual-node \
    --subnet-name myVirtualNodeSubnet
## Connect to the cluster

az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Deploy a sample app

## Test the virtual node pod

## Remove virtual nodes

az aks disable-addons --resource-group myResourceGroup --name myAKSCluster --addons virtual-node
# Change the name of your resource group, cluster and network resources as needed
RES_GROUP=myResourceGroup
AKS_CLUSTER=myAKScluster
AKS_VNET=myVnet
AKS_SUBNET=myVirtualNodeSubnet
## Next steps
