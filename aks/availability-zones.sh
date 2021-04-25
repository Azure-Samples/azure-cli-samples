## Before you begin

## Limitations and region availability

## Overview of availability zones for AKS clusters

## Create an AKS cluster across availability zones

az group create --name myResourceGroup --location eastus2
## Verify node distribution across zones

az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Verify pod distribution across zones

az aks scale \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 5
## Next steps
