FILTER="displayname eq '<group-name>'"
DISPLAY_NAME=myAKSAdminGroup
MAIL_NICKNAME=myAKSAdminGroup
LOCATION=centralus
RESOURCE_GROUP=myResourceGroup
## Azure AD authentication overview

## Limitations 

## Prerequisites

sudo az aks install-cli
kubectl version --client
kubelogin --version
## Before you begin

# List existing groups in the directory
az ad group list --filter $FILTER -o table
# Create an Azure AD group
az ad group create --display-name $DISPLAY_NAME --mail-nickname $MAIL_NICKNAME
## Create an AKS cluster with Azure AD enabled

# Create an Azure resource group
az group create --name myResourceGroup --location $LOCATION
# Create an AKS-managed Azure AD cluster
az aks create -g myResourceGroup -n myManagedCluster --aad-admin-group-object-ids <id> [--aad-tenant-id <id>]
## Access an Azure AD enabled cluster

 az aks get-credentials --resource-group myResourceGroup --name myManagedCluster
kubectl get nodes
## Troubleshooting access issues with Azure AD

az aks get-credentials --resource-group $RESOURCE_GROUP --name myManagedCluster
## Enable AKS-managed Azure AD Integration on your existing cluster

az aks update -g MyResourceGroup -n MyManagedCluster --aad-admin-group-object-ids <id-1> [--aad-tenant-id <id>]
## Upgrading to AKS-managed Azure AD Integration

az aks update -g myResourceGroup -n myManagedCluster --aad-admin-group-object-ids <id> [--aad-tenant-id <id>]
## Non-interactive sign in with kubelogin

## Use Conditional Access with Azure AD and AKS

 az aks get-credentials --resource-group myResourceGroup --name myManagedCluster
kubectl get nodes
## Configure just-in-time cluster access with Azure AD and AKS

 az aks get-credentials --resource-group myResourceGroup --name myManagedCluster
kubectl get nodes
## Next steps
