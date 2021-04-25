## Create a resource group

RESOURCE_GROUP_NAME=java-liberty-project
az group create --name $RESOURCE_GROUP_NAME --location eastus
## Create an ACR instance

REGISTRY_NAME=youruniqueacrname
az acr create --resource-group $RESOURCE_GROUP_NAME --name $REGISTRY_NAME --sku Basic --admin-enabled
LOGIN_SERVER=$(az acr show -n $REGISTRY_NAME --query 'loginServer' -o tsv)
USER_NAME=$(az acr credential show -n $REGISTRY_NAME --query 'username' -o tsv)
PASSWORD=$(az acr credential show -n $REGISTRY_NAME --query 'passwords[0].value' -o tsv)
## Create an AKS cluster

CLUSTER_NAME=myAKSCluster
az aks create --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --node-count 1 --generate-ssh-keys --enable-managed-identity
az aks install-cli
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --overwrite-existing
kubectl get nodes
## Install Open Liberty Operator

OPERATOR_NAMESPACE=default
WATCH_NAMESPACE='""'
## Build application image

## Deploy application on the AKS cluster

kubectl get service javaee-app-simple-cluster --watch
## Clean up the resources

az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait
## Next steps
