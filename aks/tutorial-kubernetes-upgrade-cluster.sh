RESOURCE_GROUP=myResourceGroup
KUBERNETES_VERSION=KUBERNETES_VERSION
## Before you begin

## Get available cluster versions

az aks get-upgrades --resource-group $RESOURCE_GROUP --name myAKSCluster
## Upgrade a cluster

az aks upgrade --resource-group $RESOURCE_GROUP --name myAKSCluster --kubernetes-version $KUBERNETES_VERSION
## Validate an upgrade

az aks show --resource-group $RESOURCE_GROUP --name myAKSCluster --output table
## Delete the cluster

az group delete --name myResourceGroup
## Next steps
