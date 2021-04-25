RESOURCE_GROUP=myResourceGroup
NAME=myAKSCluster
NODE_COUNT=3
## Before you begin

## Manually scale pods

## Autoscale pods

az aks show --resource-group $RESOURCE_GROUP --name $NAME --query kubernetesVersion --output table
## Manually scale AKS nodes

az aks scale --resource-group $RESOURCE_GROUP --name $NAME --node-count $NODE_COUNT
## Next steps
