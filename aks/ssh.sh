PUBLISHER=Microsoft.OSTCExtensions
VERSION=1.4
PROTECTED_SETTINGS="{\"username\":\"azureuser\", \"ssh_key\":\"$(cat ~/.ssh/id_rsa.pub)\"}"
USERNAME=azureuser
SSH_KEY_VALUE=~/.ssh/id_rsa.pub
## Before you begin

## Configure virtual machine scale set-based AKS clusters for SSH access

CLUSTER_RESOURCE_GROUP=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv)
SCALE_SET_NAME=$(az vmss list --resource-group $CLUSTER_RESOURCE_GROUP --query '[0].name' -o tsv)
az vmss extension set  --resource-group $CLUSTER_RESOURCE_GROUP --vmss-name $SCALE_SET_NAME --name VMAccessForLinux --publisher $PUBLISHER --version $VERSION --protected-settings $PROTECTED_SETTINGS
## Configure virtual machine availability set-based AKS clusters for SSH access

CLUSTER_RESOURCE_GROUP=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv)
az vm list --resource-group $CLUSTER_RESOURCE_GROUP -o table
az vm user update --resource-group $CLUSTER_RESOURCE_GROUP --name aks-nodepool1-79590246-0 --username $USERNAME --ssh-key-value $SSH_KEY_VALUE
az vm list-ip-addresses --resource-group $CLUSTER_RESOURCE_GROUP -o table
## Create the SSH connection

## Remove SSH access

## Next steps
