## Before you begin

az feature register --namespace "Microsoft.ContainerService" --name "EnableUltraSSD"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableUltraSSD')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
# Install the aks-preview extension
az extension add --name aks-preview
## Create a new cluster that can use Ultra disks

# Create an Azure resource group
az group create --name myResourceGroup --location westus2
# Create an AKS-managed Azure AD cluster
az aks create -g MyResourceGroup -n MyManagedCluster -l westus2 --node-vm-size Standard_L8s_v2 --zones 1 2 --node-count 2 --aks-custom-headers EnableUltraSSD=true
## Enable Ultra disks on an existing cluster

az aks nodepool add --name ultradisk --cluster-name myAKSCluster --resource-group myResourceGroup --node-vm-size Standard_L8s_v2 --zones 1 2 --node-count 2 --aks-custom-headers EnableUltraSSD=true
## Use ultra disks dynamically with a storage class

## Create a persistent volume claim

## Use the persistent volume

## Next steps
