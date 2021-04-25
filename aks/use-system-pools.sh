LOCATION=eastus
G=myResourceGroup
RESOURCE_GROUP=myResourceGroup
CLUSTER_NAME=myAKSCluster
NODE_TAINTS=CriticalAddonsOnly=true:NoSchedule
## Before you begin

## Limitations

## System and user node pools

## Create a new AKS cluster with a system node pool

az group create --name myResourceGroup --location $LOCATION
# Create a new AKS cluster with a single system pool
az aks create -g $G --name myAKSCluster --node-count 1
## Add a dedicated system node pool to an existing AKS cluster

az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name systempool --node-count 3 --node-taints $NODE_TAINTS --mode System
## Show details for your node pool

az aks nodepool show -g $G --cluster-name $CLUSTER_NAME -n systempool
## Update existing cluster system and user node pools

az aks nodepool update -g $G --cluster-name $CLUSTER_NAME -n mynodepool --mode user
az aks nodepool update -g $G --cluster-name $CLUSTER_NAME -n mynodepool --mode system
## Delete a system node pool

az aks nodepool delete -g $G --cluster-name $CLUSTER_NAME -n mynodepool
## Clean up resources

az group delete --name myResourceGroup
## Next steps
