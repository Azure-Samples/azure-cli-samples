## Scale the cluster nodes

az aks show --resource-group myResourceGroup --name myAKSCluster --query agentPoolProfiles
az aks scale --resource-group myResourceGroup --name myAKSCluster --node-count 1 --nodepool-name <your node pool name>
## Scale `User` node pools to 0

az aks nodepool scale --name <your node pool name> --cluster-name myAKSCluster --resource-group myResourceGroup  --node-count 0 
## Next steps
