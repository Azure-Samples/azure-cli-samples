N=myAKSCluster
IMAGE=win2019datacenter
ADMIN_USERNAME=azureuser
ADMIN_PASSWORD=myP@ssw0rd12
PRIORITY=100
DESTINATION_PORT_RANGE=3389
PROTOCOL=Tcp
DESCRIPTION="Temporary RDP access to Windows nodes"
## Before you begin

## Deploy a virtual machine to the same subnet as your cluster

CLUSTER_RG=$(az aks show -g myResourceGroup -n myAKSCluster --query nodeResourceGroup -o tsv)
VNET_NAME=$(az network vnet list -g $CLUSTER_RG --query [0].name -o tsv)
SUBNET_NAME=$(az network vnet subnet list -g $CLUSTER_RG --vnet-name $VNET_NAME --query [0].name -o tsv)
SUBNET_ID=$(az network vnet subnet show -g $CLUSTER_RG --vnet-name $VNET_NAME --name $SUBNET_NAME --query id -o tsv)
az vm create --resource-group myResourceGroup --name myVM --image $IMAGE --admin-username $ADMIN_USERNAME --admin-password $ADMIN_PASSWORD --subnet $SUBNET_ID --query publicIpAddress -o tsv
## Allow access to the virtual machine

CLUSTER_RG=$(az aks show -g myResourceGroup -n myAKSCluster --query nodeResourceGroup -o tsv)
NSG_NAME=$(az network nsg list -g $CLUSTER_RG --query [].name -o tsv)
az network nsg rule create --name tempRDPAccess --resource-group $CLUSTER_RG --nsg-name $NSG_NAME --priority $PRIORITY --destination-port-range $DESTINATION_PORT_RANGE --protocol $PROTOCOL --description $DESCRIPTION
## Get the node address

az aks install-cli
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
## Connect to the virtual machine and node

## Remove RDP access

az vm delete --resource-group myResourceGroup --name myVM
CLUSTER_RG=$(az aks show -g myResourceGroup -n myAKSCluster --query nodeResourceGroup -o tsv)
NSG_NAME=$(az network nsg list -g $CLUSTER_RG --query [].name -o tsv)
az network nsg rule delete --resource-group $CLUSTER_RG --nsg-name $NSG_NAME --name tempRDPAccess
## Next steps
