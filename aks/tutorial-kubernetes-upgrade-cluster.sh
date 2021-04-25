## Before you begin

## Get available cluster versions

az aks get-upgrades --resource-group myResourceGroup --name myAKSCluster
## Upgrade a cluster

az aks upgrade \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --kubernetes-version KUBERNETES_VERSION
## Validate an upgrade

az aks show --resource-group myResourceGroup --name myAKSCluster --output table
## Delete the cluster

az group delete --name myResourceGroup --yes --no-wait
## Next steps
