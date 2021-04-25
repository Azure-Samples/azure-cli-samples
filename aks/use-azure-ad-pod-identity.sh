LOCATION=eastus
NETWORK_PLUGIN=azure
ROLE="Reader"
ASSIGNEE="$IDENTITY_CLIENT_ID"
CLUSTER_NAME=myAKSCluster
${IDENTITY_RESOURCE_ID}=""
F=demo.yaml
## Before you begin

az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
# Install the aks-preview extension
az extension add --name aks-preview
## Create an AKS cluster with Azure CNI

az group create --name myResourceGroup --location $LOCATION
az aks create -g myResourceGroup -n myAKSCluster --network-plugin $NETWORK_PLUGIN
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Update an existing AKS cluster with Azure CNI

az aks update -g $MY_RESOURCE_GROUP -n $MY_CLUSTER --network-plugin $NETWORK_PLUGIN
## Using Kubenet network plugin with Azure Active Directory pod-managed identities 

## Mitigation

## Create an AKS cluster with Kubenet network plugin

az aks create -g $MY_RESOURCE_GROUP -n $MY_CLUSTER
## Update an existing AKS cluster with Kubenet network plugin

az aks update -g $MY_RESOURCE_GROUP -n $MY_CLUSTER
## Create an identity

az group create --name myIdentityResourceGroup --location $LOCATION
export IDENTITY_RESOURCE_GROUP="myIdentityResourceGroup"
export IDENTITY_NAME="application-identity"
az identity create --resource-group ${IDENTITY_RESOURCE_GROUP} --name ${IDENTITY_NAME}
export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"
## Assign permissions for the managed identity

NODE_GROUP=$(az aks show -g myResourceGroup -n myAKSCluster --query nodeResourceGroup -o tsv)
NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP -o tsv --query "id")
az role assignment create --role $ROLE --assignee $ASSIGNEE --scope $NODES_RESOURCE_ID
## Create a pod identity

export POD_IDENTITY_NAME="my-pod-identity"
export POD_IDENTITY_NAMESPACE="my-app"
az aks pod-identity add --resource-group myResourceGroup --cluster-name $CLUSTER_NAME --namespace ${POD_IDENTITY_NAMESPACE}  --name ${POD_IDENTITY_NAME} --identity-resource-id ${IDENTITY_RESOURCE_ID}
## Run a sample application

kubectl apply -f demo.yaml --namespace $POD_IDENTITY_NAMESPACE
kubectl logs demo --follow --namespace $POD_IDENTITY_NAMESPACE
## Clean up

kubectl delete pod demo --namespace $POD_IDENTITY_NAMESPACE
az aks pod-identity delete --name ${POD_IDENTITY_NAME} --namespace ${POD_IDENTITY_NAMESPACE} --resource-group myResourceGroup --cluster-name $CLUSTER_NAME
az identity delete -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME}
## Next steps
