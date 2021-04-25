## Which Windows operating systems are supported?

## Is Kubernetes different on Windows and Linux?

## What kind of disks are supported for Windows?

## Can I run Windows only clusters in AKS?

## How do I patch my Windows nodes?

## What network plug-ins are supported?

## Is preserving the client source IP supported?

## Can I change the max. # of pods per node?

## Why am I seeing an error when I try to create a new Windows agent pool?

## How do I rotate the service principal for my Windows node pool?

## How many node pools can I create?

## What can I name my Windows node pools?

## Are all features supported with Windows nodes?

## Can I run ingress controllers on Windows nodes?

## Can I use Azure Dev Spaces with Windows nodes?

## Can my Windows Server containers use gMSA?

## Can I use Azure Monitor for containers with Windows nodes and containers?

## Are there any limitations on the number of services on a cluster with Windows nodes?

## Can I use Azure Hybrid Benefit with Windows nodes?

az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --load-balancer-sku Standard \
    --windows-admin-password 'Password1234$' \
    --windows-admin-username azure \
    --network-plugin azure
    --enable-ahub
az aks update \
    --resource-group myResourceGroup
    --name myAKSCluster
    --enable-ahub
az vmss show --name myAKSCluster --resource-group MC_CLUSTERNAME
## Can I use the Kubernetes Web Dashboard with Windows containers?

## What if I need a feature that's not supported?

## Next steps
