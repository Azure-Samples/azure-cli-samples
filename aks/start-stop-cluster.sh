NAME=myAKSCluster
RESOURCE_GROUP=myResourceGroup
## Before you begin

## Stop an AKS Cluster

az aks stop --name $NAME --resource-group $RESOURCE_GROUP
## Start an AKS Cluster

az aks start --name $NAME --resource-group $RESOURCE_GROUP
## Next steps
