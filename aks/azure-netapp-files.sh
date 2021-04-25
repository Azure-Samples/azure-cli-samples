NAMESPACE=Microsoft.NetApp
LOCATION=eastus
SIZE=4
SERVICE_LEVEL=Premium
DELEGATIONS="Microsoft.NetApp/volumes"
ADDRESS_PREFIXES=10.0.0.0/28
VOLUME_NAME="myvol1"
## Before you begin

## Configure Azure NetApp Files

az provider register --namespace $NAMESPACE
az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv
az netappfiles account create --resource-group MC_myResourceGroup_myAKSCluster_eastus --location $LOCATION --account-name myaccount1
az netappfiles pool create --resource-group MC_myResourceGroup_myAKSCluster_eastus --location $LOCATION --account-name myaccount1 --pool-name mypool1 --size $SIZE --service-level $SERVICE_LEVEL
RESOURCE_GROUP=MC_myResourceGroup_myAKSCluster_eastus
VNET_NAME=$(az network vnet list --resource-group $RESOURCE_GROUP --query [].name -o tsv)
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query "id" -o tsv)
SUBNET_NAME=MyNetAppSubnet
az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_NAME --delegations $DELEGATIONS --address-prefixes $ADDRESS_PREFIXES
RESOURCE_GROUP=MC_myResourceGroup_myAKSCluster_eastus
LOCATION=eastus
ANF_ACCOUNT_NAME=myaccount1
POOL_NAME=mypool1
SERVICE_LEVEL=Premium
VNET_NAME=$(az network vnet list --resource-group $RESOURCE_GROUP --query [].name -o tsv)
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query "id" -o tsv)
SUBNET_NAME=MyNetAppSubnet
SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_NAME --query "id" -o tsv)
VOLUME_SIZE_GiB=100 # 100 GiB
UNIQUE_FILE_PATH="myfilepath2" # Please note that file path needs to be unique within all ANF Accounts
## Create the PersistentVolume

az netappfiles volume show --resource-group $RESOURCE_GROUP --account-name $ANF_ACCOUNT_NAME --pool-name $POOL_NAME --volume-name $VOLUME_NAME
## Create the PersistentVolumeClaim

## Mount with a pod

## Next steps
