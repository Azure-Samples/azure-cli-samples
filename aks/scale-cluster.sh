NODEPOOL_NAME=<your node pool name>
CLUSTER_NAME=myAKSCluster
## Scale the cluster nodes

az aks show --resource-group myResourceGroup --name myAKSCluster --query agentPoolProfiles
az aks scale --resource-group myResourceGroup --name myAKSCluster --node-count 1 --nodepool-name $NODEPOOL_NAME
## Scale `User` node pools to 0

az aks nodepool scale --name <your node pool name> --cluster-name $CLUSTER_NAME --resource-group myResourceGroup  --node-count 0 
## Next steps
