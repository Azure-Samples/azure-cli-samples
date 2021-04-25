## Before you begin

## Create an AKS cluster

az group create --name myResourceGroup --location eastus
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-vm-size Standard_NC6 \
    --node-count 1
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Install NVIDIA device plugin

## Use the AKS specialized GPU image (preview)

az feature register --name GPUDedicatedVHDPreview --namespace Microsoft.ContainerService
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/GPUDedicatedVHDPreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
az extension add --name aks-preview
az extension update --name aks-preview
az aks create --name myAKSCluster --resource-group myResourceGroup --node-vm-size Standard_NC6 --node-count 1 --aks-custom-headers UseGPUDedicatedVHD=true
az aks nodepool add --name gpu --cluster-name myAKSCluster --resource-group myResourceGroup --node-vm-size Standard_NC6 --node-count 1 --aks-custom-headers UseGPUDedicatedVHD=true
## Confirm that GPUs are schedulable

## Run a GPU-enabled workload

## View the status and output of the GPU-enabled workload

## Clean up resources

## Next steps
