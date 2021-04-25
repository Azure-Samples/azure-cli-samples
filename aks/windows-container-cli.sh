LOCATION=eastus
RESOURCE_GROUP=myResourceGroup
ENABLE_ADDONS=monitoring
$WINDOWS_USERNAME=""
VM_SET_TYPE=VirtualMachineScaleSets
NETWORK_PLUGIN=azure
CLUSTER_NAME=myAKSCluster
OS_TYPE=Windows
## Create a resource group

az group create --name myResourceGroup --location $LOCATION
## Create an AKS cluster

echo "Please enter the username to use as administrator credentials for Windows Server containers on your cluster: " && read WINDOWS_USERNAME
az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --node-count 2 --enable-addons $ENABLE_ADDONS --windows-admin-username $WINDOWS_USERNAME --vm-set-type $VM_SET_TYPE --network-plugin $NETWORK_PLUGIN
## Add a Windows Server node pool

az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --os-type $OS_TYPE --name npwin --node-count 1
## Connect to the cluster

az aks install-cli
az aks get-credentials --resource-group $RESOURCE_GROUP --name myAKSCluster
## Run the application

## Test the application

## Delete cluster

az group delete --name myResourceGroup
## Next steps
