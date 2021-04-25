RESOURCE_GROUP=myResourceGroup
KUBERNETES_VERSION=1.18.14
CLUSTER_NAME=myAKSCluster
S=Standard_DS3_v2
NODE_OSDISK_TYPE=Ephemeral
NODE_RESOURCE_GROUP=myNodeResourceGroup
## OS configuration

az aks create --name myAKSCluster --resource-group $RESOURCE_GROUP --kubernetes-version $KUBERNETES_VERSION
az aks upgrade --name myAKSCluster --resource-group $RESOURCE_GROUP --kubernetes-version $KUBERNETES_VERSION
az aks nodepool upgrade -name ubuntu1804 --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --kubernetes-version $KUBERNETES_VERSION
az aks upgrade --name myAKSCluster --resource-group $RESOURCE_GROUP --kubernetes-version $KUBERNETES_VERSION
## Container runtime configuration

## Generation 2 virtual machines

## Ephemeral OS

az aks create --name myAKSCluster --resource-group $RESOURCE_GROUP -s $S --node-osdisk-type $NODE_OSDISK_TYPE
az aks nodepool add --name ephemeral --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP -s $S --node-osdisk-type $NODE_OSDISK_TYPE
## Custom resource group name

az aks create --name myAKSCluster --resource-group $RESOURCE_GROUP --node-resource-group $NODE_RESOURCE_GROUP
## Next steps
