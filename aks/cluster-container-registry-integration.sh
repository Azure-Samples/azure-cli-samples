G=myResourceGroup
SOURCE=docker.io/library/nginx:latest
IMAGE=nginx:v1
## Before you begin

## Create a new AKS cluster with ACR integration

# set this to the name of your Azure Container Registry.  It must be globally unique
MYACR=myContainerRegistry
az aks create -n myAKSCluster -g $G --attach-acr /subscriptions/<subscription-id>/resourceGroups/myContainerRegistryResourceGroup/providers/Microsoft.ContainerRegistry/registries/myContainerRegistry
## Configure ACR integration for existing AKS clusters

az aks update -n myAKSCluster -g $G --attach-acr <acr-name>
az aks update -n myAKSCluster -g $G --attach-acr <acr-resource-id>
az aks update -n myAKSCluster -g $G --detach-acr <acr-name>
az aks update -n myAKSCluster -g $G --detach-acr <acr-resource-id>
## Working with ACR & AKS

az acr import  -n <acr-name> --source $SOURCE --image $IMAGE
az aks get-credentials -g $G -n myAKSCluster