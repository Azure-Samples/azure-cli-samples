LOCATION=centralus
N=myPPG
G=myResourceGroup
L=centralus
T=standard
RESOURCE_GROUP=myResourceGroup
PPG=myPPGResourceID
CLUSTER_NAME=myAKSCluster
NODE_COUNT=1
## Before you begin

## Node pools and proximity placement groups

## Create a new AKS cluster with a proximity placement group

# Create an Azure resource group
az group create --name myResourceGroup --location $LOCATION
# Create proximity placement group
az ppg create -n $N -g $G -l $L -t $T
# Create an AKS cluster that uses a proximity placement group for the initial system node pool only. The PPG has no effect on the cluster control plane.
az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --ppg $PPG
## Add a proximity placement group to an existing cluster

# Add a new node pool that uses a proximity placement group, use a --node-count = 1 for testing
az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name mynodepool --node-count $NODE_COUNT --ppg $PPG
## Clean up

az group delete --name myResourceGroup
## Next steps
