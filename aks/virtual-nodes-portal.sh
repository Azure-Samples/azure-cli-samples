## Before you begin

az provider list --query "[?contains(namespace,'Microsoft.ContainerInstance')]" -o table
az provider register --namespace Microsoft.ContainerInstance
## Sign in to Azure

## Create an AKS cluster

## Connect to the cluster

az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Deploy a sample app

kubectl apply -f virtual-node.yaml
## Test the virtual node pod

## Next steps
