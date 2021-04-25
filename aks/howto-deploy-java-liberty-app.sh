LOCATION=eastus
$RESOURCE_GROUP_NAME=""
SKU=Basic
$REGISTRY_NAME=""
NODE_COUNT=1
## Create a resource group

RESOURCE_GROUP_NAME=java-liberty-project
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
## Create an ACR instance

REGISTRY_NAME=youruniqueacrname
az acr create --resource-group $RESOURCE_GROUP_NAME --name $REGISTRY_NAME --sku $SKU
LOGIN_SERVER=$(az acr show -n $REGISTRY_NAME --query 'loginServer' -o tsv)
USER_NAME=$(az acr credential show -n $REGISTRY_NAME --query 'username' -o tsv)
PASSWORD=$(az acr credential show -n $REGISTRY_NAME --query 'passwords[0].value' -o tsv)
## Create an AKS cluster

CLUSTER_NAME=myAKSCluster
az aks create --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --node-count $NODE_COUNT
az aks install-cli
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME
kubectl get nodes
## Install Open Liberty Operator

OPERATOR_NAMESPACE=default
WATCH_NAMESPACE='""'
## Build application image

## Deploy application on the AKS cluster

kubectl get service javaee-app-simple-cluster --watch
## Clean up the resources

az group delete --name $RESOURCE_GROUP_NAME
## Next steps
