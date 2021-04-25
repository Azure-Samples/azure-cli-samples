LOCATION=westus2
G=MyResourceGroup
N=MyManagedCluster
L=westus2
NODE_VM_SIZE=Standard_L8s_v2
ZONES=1 2
NODE_COUNT=2
AKS_CUSTOM_HEADERS=EnableUltraSSD=true
CLUSTER_NAME=myAKSCluster
RESOURCE_GROUP=myResourceGroup
## Before you begin

az feature register --namespace "Microsoft.ContainerService" --name "EnableUltraSSD"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableUltraSSD')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
# Install the aks-preview extension
az extension add --name aks-preview
## Create a new cluster that can use Ultra disks

# Create an Azure resource group
az group create --name myResourceGroup --location $LOCATION
# Create an AKS-managed Azure AD cluster
az aks create -g $G -n $N -l $L --node-vm-size $NODE_VM_SIZE --zones $ZONES --node-count $NODE_COUNT --aks-custom-headers $AKS_CUSTOM_HEADERS
## Enable Ultra disks on an existing cluster

az aks nodepool add --name ultradisk --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size $NODE_VM_SIZE --zones $ZONES --node-count $NODE_COUNT --aks-custom-headers $AKS_CUSTOM_HEADERS
## Use ultra disks dynamically with a storage class

## Create a persistent volume claim

## Use the persistent volume

## Next steps
