LOCATION=eastus
RESOURCE_GROUP=myResourceGroup  
ENABLE_CLUSTER_AUTOSCALER= 
MIN_COUNT=1  
UPDATE_CLUSTER_AUTOSCALER= 
CLUSTER_NAME=myAKSCluster  
NODE_COUNT=1  
## Before you begin

## About the cluster autoscaler

## Create an AKS cluster and enable the cluster autoscaler

# First create a resource group
az group create --name myResourceGroup --location $LOCATION
## Update an existing AKS cluster to enable the cluster autoscaler

az aks update   --resource-group $RESOURCE_GROUP --name myAKSCluster   --enable-cluster-autoscaler $ENABLE_CLUSTER_AUTOSCALER --min-count $MIN_COUNT --max-count 3
## Change the cluster autoscaler settings

az aks update   --resource-group $RESOURCE_GROUP --name myAKSCluster   --update-cluster-autoscaler $UPDATE_CLUSTER_AUTOSCALER --min-count $MIN_COUNT --max-count 5
## Using the autoscaler profile

az aks update   --resource-group $RESOURCE_GROUP --name myAKSCluster   --cluster-autoscaler-profile scan-interval=30s
az aks nodepool update   --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name mynodepool   --enable-cluster-autoscaler $ENABLE_CLUSTER_AUTOSCALER --min-count $MIN_COUNT --max-count 3
az aks create   --resource-group $RESOURCE_GROUP --name myAKSCluster   --node-count $NODE_COUNT --enable-cluster-autoscaler $ENABLE_CLUSTER_AUTOSCALER --min-count $MIN_COUNT --max-count 3   --cluster-autoscaler-profile scan-interval=30s
az aks update   --resource-group $RESOURCE_GROUP --name myAKSCluster   --cluster-autoscaler-profile ""
## Disable the cluster autoscaler

az aks update   --resource-group $RESOURCE_GROUP --name myAKSCluster  
## Re-enable a disabled cluster autoscaler

## Retrieve cluster autoscaler logs and status

## Use the cluster autoscaler with multiple node pools enabled

az aks nodepool update   --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name nodepool1   --update-cluster-autoscaler $UPDATE_CLUSTER_AUTOSCALER --min-count $MIN_COUNT --max-count 5
az aks nodepool update   --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name nodepool1  
## Next steps
