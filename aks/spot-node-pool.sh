## Before you begin

## Add a spot node pool to an AKS cluster

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name spotnodepool \
    --priority Spot \
    --eviction-policy Delete \
    --spot-max-price -1 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --no-wait
## Verify the spot node pool

az aks nodepool show --resource-group myResourceGroup --cluster-name myAKSCluster --name spotnodepool
## Max price for a spot pool

## Next steps
