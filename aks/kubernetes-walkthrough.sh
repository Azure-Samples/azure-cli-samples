## Create a resource group

az group create --name myResourceGroup --location eastus
## Enable cluster monitoring

## Create AKS cluster

az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 1 --enable-addons monitoring --generate-ssh-keys
## Connect to the cluster

## Run the application

## Test the application

kubectl get service azure-vote-front --watch
## Delete the cluster

az group delete --name myResourceGroup --yes --no-wait
## Get the code

## Next steps
