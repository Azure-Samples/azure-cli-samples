## Before you begin

## Manually scale pods

## Autoscale pods

az aks show --resource-group myResourceGroup --name myAKSCluster --query kubernetesVersion --output table
## Manually scale AKS nodes

az aks scale --resource-group myResourceGroup --name myAKSCluster --node-count 3
## Next steps
