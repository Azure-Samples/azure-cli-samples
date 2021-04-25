LOCATION=eastus
VNET_SUBNET_ID=<YOUR_SUBNET_RESOURCE_ID>
KUBERNETES_VERSION=KUBERNETES_VERSION
NODE_VM_SIZE=Standard_NC6
NODE_TAINTS=sku=gpu:NoSchedule
LABELS=dept=IT costcenter=9999
TAGS=dept=IT costcenter=9999
TEMPLATE_FILE=aks-agentpools.json
LENGTH=28
NODE_PUBLIC_IP_PREFIX=/subscriptions/<subscription-id>/resourcegroups/MyResourceGroup3/providers/Microsoft.Network/publicIPPrefixes/MyPublicIPPrefix
## Before you begin

## Limitations

## Create an AKS cluster

# Create a resource group in East US
az group create --name myResourceGroup --location $LOCATION
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Add a node pool

az aks nodepool add --resource-group myResourceGroup --cluster-name myAKSCluster --name mynodepool --node-count 3
az aks nodepool list --resource-group myResourceGroup --cluster-name myAKSCluster
az aks nodepool add --resource-group myResourceGroup --cluster-name myAKSCluster --name mynodepool --node-count 3 --vnet-subnet-id $VNET_SUBNET_ID
## Upgrade a node pool

az aks get-upgrades --resource-group myResourceGroup --name myAKSCluster
az aks nodepool upgrade --resource-group myResourceGroup --cluster-name myAKSCluster --name mynodepool --kubernetes-version $KUBERNETES_VERSION
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Upgrade a cluster control plane with multiple node pools

## Scale a node pool manually

az aks nodepool scale --resource-group myResourceGroup --cluster-name myAKSCluster --name mynodepool --node-count 5
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Scale a specific node pool automatically by enabling the cluster autoscaler

## Delete a node pool

az aks nodepool delete -g myResourceGroup --cluster-name myAKSCluster --name mynodepool
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Specify a VM size for a node pool

az aks nodepool add --resource-group myResourceGroup --cluster-name myAKSCluster --name gpunodepool --node-count 1 --node-vm-size $NODE_VM_SIZE
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Specify a taint, label, or tag for a node pool

az aks nodepool add --resource-group myResourceGroup --cluster-name myAKSCluster --name taintnp --node-count 1 --node-taints $NODE_TAINTS
az aks nodepool add --resource-group myResourceGroup --cluster-name myAKSCluster --name labelnp --node-count 1 --labels $LABELS
az aks nodepool add --resource-group myResourceGroup --cluster-name myAKSCluster --name tagnodepool --node-count 1 --tags $TAGS
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Manage node pools using a Resource Manager template

az deployment group create --resource-group myResourceGroup --template-file $TEMPLATE_FILE
## Assign a public IP per node for your node pools

az group create --name myResourceGroup2 --location $LOCATION
az aks create -g MyResourceGroup2 -n MyManagedCluster -l eastus 
az aks nodepool add -g MyResourceGroup2 --cluster-name MyManagedCluster -n nodepool2
az network public-ip prefix create --length $LENGTH --location $LOCATION --name MyPublicIPPrefix --resource-group MyResourceGroup3
az aks create -g MyResourceGroup3 -n MyManagedCluster -l eastus --node-public-ip-prefix $NODE_PUBLIC_IP_PREFIX
az vmss list-instance-public-ips -g MC_MyResourceGroup2_MyManagedCluster_eastus -n YourVirtualMachineScaleSetName
## Clean up resources

az aks nodepool delete -g myResourceGroup --cluster-name myAKSCluster --name gpunodepool
az group delete --name myResourceGroup
az group delete --name myResourceGroup2
## Next steps
