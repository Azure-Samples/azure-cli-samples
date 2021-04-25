LOCATION=eastus
RESOURCE_GROUP=myResourceGroup
NODE_COUNT=1
ENABLE_ADDONS=monitoring
## Create a resource group

az group create --name myResourceGroup --location $LOCATION
## Enable cluster monitoring

## Create AKS cluster

az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --node-count $NODE_COUNT --enable-addons $ENABLE_ADDONS
## Connect to the cluster

## Run the application

## Test the application

kubectl get service azure-vote-front --watch
## Delete the cluster

az group delete --name myResourceGroup
## Get the code

## Next steps
