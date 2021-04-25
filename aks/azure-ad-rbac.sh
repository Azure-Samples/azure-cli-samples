## Before you begin

## Create demo groups in Azure AD

AKS_ID=$(az aks show \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --query id -o tsv)
APPDEV_ID=$(az ad group create --display-name appdev --mail-nickname appdev --query objectId -o tsv)
az role assignment create \
  --assignee $APPDEV_ID \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope $AKS_ID
OPSSRE_ID=$(az ad group create --display-name opssre --mail-nickname opssre --query objectId -o tsv)
az role assignment create \
  --assignee $OPSSRE_ID \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope $AKS_ID
## Create demo users in Azure AD

echo "Please enter the UPN for application developers: " && read AAD_DEV_UPN
echo "Please enter the secure password for application developers: " && read AAD_DEV_PW
AKSDEV_ID=$(az ad user create \
  --display-name "AKS Dev" \
  --user-principal-name $AAD_DEV_UPN \
  --password $AAD_DEV_PW \
  --query objectId -o tsv)
az ad group member add --group appdev --member-id $AKSDEV_ID
echo "Please enter the UPN for SREs: " && read AAD_SRE_UPN
echo "Please enter the secure password for SREs: " && read AAD_SRE_PW
# Create a user for the SRE role
AKSSRE_ID=$(az ad user create \
  --display-name "AKS SRE" \
  --user-principal-name $AAD_SRE_UPN \
  --password $AAD_SRE_PW \
  --query objectId -o tsv)
## Create the AKS cluster resources for app devs

az aks get-credentials --resource-group myResourceGroup --name myAKSCluster --admin
az ad group show --group appdev --query objectId -o tsv
## Create the AKS cluster resources for SREs

az ad group show --group opssre --query objectId -o tsv
## Interact with cluster resources using Azure AD identities

az aks get-credentials --resource-group myResourceGroup --name myAKSCluster --overwrite-existing
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster --overwrite-existing
## Clean up resources

# Get the admin kubeconfig context to delete the necessary cluster resources
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster --admin
## Next steps
