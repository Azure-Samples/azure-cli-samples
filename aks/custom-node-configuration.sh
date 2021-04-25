## Register the `CustomNodeConfigPreview` preview feature

az feature register --namespace "Microsoft.ContainerService" --name "CustomNodeConfigPreview"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/CustomNodeConfigPreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
## Install aks-preview CLI extension

# Install the aks-preview extension
az extension add --name aks-preview
## Use custom node configuration

az aks create --name myAKSCluster --resource-group myResourceGroup --kubelet-config ./kubeletconfig.json --linux-os-config ./linuxosconfig.json
az aks nodepool add --name mynodepool1 --cluster-name myAKSCluster --resource-group myResourceGroup --kubelet-config ./kubeletconfig.json
## Next steps
