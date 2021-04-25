## Create a resource group

az group create --name myResourceGroup --location eastus
## Create an AKS cluster

echo "Please enter the username to use as administrator credentials for Windows Server containers on your cluster: " && read WINDOWS_USERNAME
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 2 \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --windows-admin-username $WINDOWS_USERNAME \
    --vm-set-type VirtualMachineScaleSets \
    --network-plugin azure
## Add a Windows Server node pool

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --os-type Windows \
    --name npwin \
    --node-count 1
## Connect to the cluster

az aks install-cli
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Run the application

## Test the application

## Delete cluster

az group delete --name myResourceGroup --yes --no-wait
## Next steps
