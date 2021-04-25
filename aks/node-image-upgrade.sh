NODEPOOL_NAME=mynodepool
CLUSTER_NAME=myAKSCluster
RESOURCE_GROUP=myResourceGroup
MAX_SURGE=33%
## Check if your node pool is on the latest node image

az aks nodepool get-upgrades --nodepool-name $NODEPOOL_NAME --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP
az aks nodepool show --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name mynodepool --query nodeImageVersion
## Upgrade all nodes in all node pools

az aks upgrade --resource-group $RESOURCE_GROUP --name myAKSCluster
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.kubernetes\.azure\.com\/node-image-version}{"\n"}{end}'
az aks show --resource-group $RESOURCE_GROUP --name myAKSCluster
## Upgrade a specific node pool

az aks nodepool upgrade --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name mynodepool
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.kubernetes\.azure\.com\/node-image-version}{"\n"}{end}'
az aks nodepool show --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name mynodepool
## Upgrade node images with node surge

az aks nodepool upgrade --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name mynodepool --max-surge $MAX_SURGE
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.kubernetes\.azure\.com\/node-image-version}{"\n"}{end}'
az aks nodepool show --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name mynodepool
## Next steps
