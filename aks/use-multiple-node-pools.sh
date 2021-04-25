## Before you begin

## Limitations

## Create an AKS cluster

# Create a resource group in East US
az group create --name myResourceGroup --location eastus
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Add a node pool

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 3
az aks nodepool list --resource-group myResourceGroup --cluster-name myAKSCluster
az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 3 \
    --vnet-subnet-id <YOUR_SUBNET_RESOURCE_ID>
## Upgrade a node pool

az aks get-upgrades --resource-group myResourceGroup --name myAKSCluster
az aks nodepool upgrade \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --kubernetes-version KUBERNETES_VERSION \
    --no-wait
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Upgrade a cluster control plane with multiple node pools

## Scale a node pool manually

az aks nodepool scale \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 5 \
    --no-wait
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Scale a specific node pool automatically by enabling the cluster autoscaler

## Delete a node pool

az aks nodepool delete -g myResourceGroup --cluster-name myAKSCluster --name mynodepool --no-wait
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Specify a VM size for a node pool

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name gpunodepool \
    --node-count 1 \
    --node-vm-size Standard_NC6 \
    --no-wait
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Specify a taint, label, or tag for a node pool

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name taintnp \
    --node-count 1 \
    --node-taints sku=gpu:NoSchedule \
    --no-wait
az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name labelnp \
    --node-count 1 \
    --labels dept=IT costcenter=9999 \
    --no-wait
az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name tagnodepool \
    --node-count 1 \
    --tags dept=IT costcenter=9999 \
    --no-wait
az aks nodepool list -g myResourceGroup --cluster-name myAKSCluster
## Manage node pools using a Resource Manager template

az deployment group create \
    --resource-group myResourceGroup \
    --template-file aks-agentpools.json
## Assign a public IP per node for your node pools

az group create --name myResourceGroup2 --location eastus
az aks create -g MyResourceGroup2 -n MyManagedCluster -l eastus  --enable-node-public-ip
az aks nodepool add -g MyResourceGroup2 --cluster-name MyManagedCluster -n nodepool2 --enable-node-public-ip
az network public-ip prefix create --length 28 --location eastus --name MyPublicIPPrefix --resource-group MyResourceGroup3
az aks create -g MyResourceGroup3 -n MyManagedCluster -l eastus --enable-node-public-ip --node-public-ip-prefix /subscriptions/<subscription-id>/resourcegroups/MyResourceGroup3/providers/Microsoft.Network/publicIPPrefixes/MyPublicIPPrefix
az vmss list-instance-public-ips -g MC_MyResourceGroup2_MyManagedCluster_eastus -n YourVirtualMachineScaleSetName
## Clean up resources

az aks nodepool delete -g myResourceGroup --cluster-name myAKSCluster --name gpunodepool
az group delete --name myResourceGroup --yes --no-wait
az group delete --name myResourceGroup2 --yes --no-wait
## Next steps
