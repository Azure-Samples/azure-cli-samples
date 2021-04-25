## Before you begin

## Create a Kubernetes cluster

az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr <acrName>
## Install the Kubernetes CLI

az aks install-cli
## Connect to cluster using kubectl

az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Next steps
