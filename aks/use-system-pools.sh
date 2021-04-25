## Before you begin

## Limitations

## System and user node pools

## Create a new AKS cluster with a system node pool

az group create --name myResourceGroup --location eastus
# Create a new AKS cluster with a single system pool
az aks create -g myResourceGroup --name myAKSCluster --node-count 1 --generate-ssh-keys
## Add a dedicated system node pool to an existing AKS cluster

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name systempool \
    --node-count 3 \
    --node-taints CriticalAddonsOnly=true:NoSchedule \
    --mode System
## Show details for your node pool

az aks nodepool show -g myResourceGroup --cluster-name myAKSCluster -n systempool
## Update existing cluster system and user node pools

az aks nodepool update -g myResourceGroup --cluster-name myAKSCluster -n mynodepool --mode user
az aks nodepool update -g myResourceGroup --cluster-name myAKSCluster -n mynodepool --mode system
## Delete a system node pool

az aks nodepool delete -g myResourceGroup --cluster-name myAKSCluster -n mynodepool
## Clean up resources

az group delete --name myResourceGroup --yes --no-wait
## Next steps
