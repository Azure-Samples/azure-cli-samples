LOCATION=eastus2
RESOURCE_GROUP=myResourceGroup
NODE_COUNT=5
## Before you begin

## Limitations and region availability

## Overview of availability zones for AKS clusters

## Create an AKS cluster across availability zones

az group create --name myResourceGroup --location $LOCATION
## Verify node distribution across zones

az aks get-credentials --resource-group $RESOURCE_GROUP --name myAKSCluster
## Verify pod distribution across zones

az aks scale --resource-group $RESOURCE_GROUP --name myAKSCluster --node-count $NODE_COUNT
## Next steps
