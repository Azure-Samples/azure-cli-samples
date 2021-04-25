RESOURCE_GROUP=myResourceGroup
KUBELET_CONFIG=./kubeletconfig.json
LINUX_OS_CONFIG=./linuxosconfig.json
CLUSTER_NAME=myAKSCluster
## Register the `CustomNodeConfigPreview` preview feature

az feature register --namespace "Microsoft.ContainerService" --name "CustomNodeConfigPreview"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/CustomNodeConfigPreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
## Install aks-preview CLI extension

# Install the aks-preview extension
az extension add --name aks-preview
## Use custom node configuration

az aks create --name myAKSCluster --resource-group $RESOURCE_GROUP --kubelet-config $KUBELET_CONFIG --linux-os-config $LINUX_OS_CONFIG
az aks nodepool add --name mynodepool1 --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --kubelet-config $KUBELET_CONFIG
## Next steps
