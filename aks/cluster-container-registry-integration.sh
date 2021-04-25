## Before you begin

## Create a new AKS cluster with ACR integration

# set this to the name of your Azure Container Registry.  It must be globally unique
MYACR=myContainerRegistry
az aks create -n myAKSCluster -g myResourceGroup --generate-ssh-keys --attach-acr /subscriptions/<subscription-id>/resourceGroups/myContainerRegistryResourceGroup/providers/Microsoft.ContainerRegistry/registries/myContainerRegistry
## Configure ACR integration for existing AKS clusters

az aks update -n myAKSCluster -g myResourceGroup --attach-acr <acr-name>
az aks update -n myAKSCluster -g myResourceGroup --attach-acr <acr-resource-id>
az aks update -n myAKSCluster -g myResourceGroup --detach-acr <acr-name>
az aks update -n myAKSCluster -g myResourceGroup --detach-acr <acr-resource-id>
## Working with ACR & AKS

az acr import  -n <acr-name> --source docker.io/library/nginx:latest --image nginx:v1
az aks get-credentials -g myResourceGroup -n myAKSCluster