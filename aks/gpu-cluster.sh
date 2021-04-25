LOCATION=eastus
RESOURCE_GROUP=myResourceGroup
NODE_VM_SIZE=Standard_NC6
NODE_COUNT=1
NAMESPACE=Microsoft.ContainerService
AKS_CUSTOM_HEADERS=UseGPUDedicatedVHD=true
CLUSTER_NAME=myAKSCluster
## Before you begin

## Create an AKS cluster

az group create --name myResourceGroup --location $LOCATION
az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --node-vm-size $NODE_VM_SIZE --node-count $NODE_COUNT
az aks get-credentials --resource-group $RESOURCE_GROUP --name myAKSCluster
## Install NVIDIA device plugin

## Use the AKS specialized GPU image (preview)

az feature register --name GPUDedicatedVHDPreview --namespace $NAMESPACE
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/GPUDedicatedVHDPreview')].{Name:name,State:properties.state}"
az provider register --namespace $NAMESPACE
az extension add --name aks-preview
az extension update --name aks-preview
az aks create --name myAKSCluster --resource-group $RESOURCE_GROUP --node-vm-size $NODE_VM_SIZE --node-count $NODE_COUNT --aks-custom-headers $AKS_CUSTOM_HEADERS
az aks nodepool add --name gpu --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size $NODE_VM_SIZE --node-count $NODE_COUNT --aks-custom-headers $AKS_CUSTOM_HEADERS
## Confirm that GPUs are schedulable

## Run a GPU-enabled workload

## View the status and output of the GPU-enabled workload

## Clean up resources

## Next steps
