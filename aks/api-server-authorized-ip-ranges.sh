RESOURCE_GROUP=myResourceGroup
NAME=myAKSCluster
NODE_COUNT=1
VM_SET_TYPE=VirtualMachineScaleSets
LOAD_BALANCER_SKU=standard
LOAD_BALANCER_OUTBOUND_IPS=<publicIpId1>,<publicIpId2>
## Before you begin

## Overview of API server authorized IP ranges

## Create an AKS cluster with API server authorized IP ranges enabled

az aks create --resource-group $RESOURCE_GROUP --name $NAME --node-count $NODE_COUNT --vm-set-type $VM_SET_TYPE --load-balancer-sku $LOAD_BALANCER_SKU --api-server-authorized-ip-ranges 73.140.245.0/24
az aks create --resource-group $RESOURCE_GROUP --name $NAME --node-count $NODE_COUNT --vm-set-type $VM_SET_TYPE --load-balancer-sku $LOAD_BALANCER_SKU --api-server-authorized-ip-ranges 73.140.245.0/24 --load-balancer-outbound-ips $LOAD_BALANCER_OUTBOUND_IPS
az aks create --resource-group $RESOURCE_GROUP --name $NAME --node-count $NODE_COUNT --vm-set-type $VM_SET_TYPE --load-balancer-sku $LOAD_BALANCER_SKU --api-server-authorized-ip-ranges 0.0.0.0/32
## Update a cluster's API server authorized IP ranges

az aks update --resource-group $RESOURCE_GROUP --name $NAME --api-server-authorized-ip-ranges  73.140.245.0/24
## Disable authorized IP ranges

az aks update --resource-group $RESOURCE_GROUP --name $NAME --api-server-authorized-ip-ranges ""
## Find existing authorized IP ranges

az aks show --resource-group $RESOURCE_GROUP --name $NAME --query apiServerAccessProfile.authorizedIpRanges'
## Update, disable, and find authorized IP ranges using Azure portal

## How to find my IP to include in `--api-server-authorized-ip-ranges`?

## Next steps
