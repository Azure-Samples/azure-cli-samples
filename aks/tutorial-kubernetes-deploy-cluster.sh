RESOURCE_GROUP=myResourceGroup
NAME=myAKSCluster
NODE_COUNT=2
ATTACH_ACR=<acrName>
## Before you begin

## Create a Kubernetes cluster

az aks create --resource-group $RESOURCE_GROUP --name $NAME --node-count $NODE_COUNT --attach-acr $ATTACH_ACR
## Install the Kubernetes CLI

az aks install-cli
## Connect to cluster using kubectl

az aks get-credentials --resource-group $RESOURCE_GROUP --name $NAME
## Next steps
