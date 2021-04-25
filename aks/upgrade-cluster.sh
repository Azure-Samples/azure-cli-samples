## Before you begin

## Check for available AKS cluster upgrades

az aks get-upgrades --resource-group myResourceGroup --name myAKSCluster --output table
## Customize node surge upgrade

# Set max surge for a new node pool
az aks nodepool add -n mynodepool -g MyResourceGroup --cluster-name MyManagedCluster --max-surge 33%
# Update max surge for an existing node pool 
az aks nodepool update -n mynodepool -g MyResourceGroup --cluster-name MyManagedCluster --max-surge 5
## Upgrade an AKS cluster

az aks upgrade \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --kubernetes-version KUBERNETES_VERSION
az aks show --resource-group myResourceGroup --name myAKSCluster --output table
## Set auto-upgrade channel

az feature register --namespace Microsoft.ContainerService -n AutoUpgradePreview
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AutoUpgradePreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
az aks create --resource-group myResourceGroup --name myAKSCluster --auto-upgrade-channel stable --generate-ssh-keys
az aks update --resource-group myResourceGroup --name myAKSCluster --auto-upgrade-channel stable
## Next steps
