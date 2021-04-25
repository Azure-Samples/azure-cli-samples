RESOURCE_GROUP=myResourceGroup
CLUSTER_NAME=myAKSCluster
NAME=spotnodepool
PRIORITY=Spot
EVICTION_POLICY=Delete
MIN_COUNT=1
MAX_COUNT=3
## Before you begin

## Add a spot node pool to an AKS cluster

az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $NAME --priority $PRIORITY --eviction-policy $EVICTION_POLICY --min-count $MIN_COUNT --max-count $MAX_COUNT
## Verify the spot node pool

az aks nodepool show --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $NAME
## Max price for a spot pool

## Next steps
