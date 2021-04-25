NAMESPACE=Microsoft.ContainerInstance
RESOURCE_GROUP=myResourceGroup
NAME=myAKSCluster
F=virtual-node.yaml
## Before you begin

az provider list --query "[?contains(namespace,'Microsoft.ContainerInstance')]" -o table
az provider register --namespace $NAMESPACE
## Sign in to Azure

## Create an AKS cluster

## Connect to the cluster

az aks get-credentials --resource-group $RESOURCE_GROUP --name $NAME
## Deploy a sample app

kubectl apply -f virtual-node.yaml
## Test the virtual node pod

## Next steps
