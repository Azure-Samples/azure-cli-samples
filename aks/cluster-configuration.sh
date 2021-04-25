## OS configuration

az aks create --name myAKSCluster --resource-group myResourceGroup --kubernetes-version 1.18.14
az aks upgrade --name myAKSCluster --resource-group myResourceGroup --kubernetes-version 1.18.14
az aks nodepool upgrade -name ubuntu1804 --cluster-name myAKSCluster --resource-group myResourceGroup --kubernetes-version 1.18.14
az aks upgrade --name myAKSCluster --resource-group myResourceGroup --kubernetes-version 1.18.14 --control-plane-only
## Container runtime configuration

## Generation 2 virtual machines

## Ephemeral OS

az aks create --name myAKSCluster --resource-group myResourceGroup -s Standard_DS3_v2 --node-osdisk-type Ephemeral
az aks nodepool add --name ephemeral --cluster-name myAKSCluster --resource-group myResourceGroup -s Standard_DS3_v2 --node-osdisk-type Ephemeral
## Custom resource group name

az aks create --name myAKSCluster --resource-group myResourceGroup --node-resource-group myNodeResourceGroup
## Next steps
