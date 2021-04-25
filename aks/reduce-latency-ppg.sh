## Before you begin

## Node pools and proximity placement groups

## Create a new AKS cluster with a proximity placement group

# Create an Azure resource group
az group create --name myResourceGroup --location centralus
# Create proximity placement group
az ppg create -n myPPG -g myResourceGroup -l centralus -t standard
# Create an AKS cluster that uses a proximity placement group for the initial system node pool only. The PPG has no effect on the cluster control plane.
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --ppg myPPGResourceID
## Add a proximity placement group to an existing cluster

# Add a new node pool that uses a proximity placement group, use a --node-count = 1 for testing
az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 1 \
    --ppg myPPGResourceID
## Clean up

az group delete --name myResourceGroup --yes --no-wait
## Next steps
