## Before you begin

az feature register --namespace "Microsoft.ContainerService" --name "EnableAzureRBACPreview"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableAzureRBACPreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
# Install the aks-preview extension
az extension add --name aks-preview
## Create a new cluster using Azure RBAC and managed Azure AD integration

# Create an Azure resource group
az group create --name myResourceGroup --location westus2
# Create an AKS-managed Azure AD cluster
az aks create -g MyResourceGroup -n MyManagedCluster --enable-aad --enable-azure-rbac
## Create role assignments for users to access cluster

az role assignment create --role "Azure Kubernetes Service RBAC Admin" --assignee <AAD-ENTITY-ID> --scope $AKS_ID
az role assignment create --role "Azure Kubernetes Service RBAC Viewer" --assignee <AAD-ENTITY-ID> --scope $AKS_ID/namespaces/<namespace-name>
az account show --query id -o tsv
az role definition create --role-definition @deploy-view.json 
az role assignment create --role "AKS Deployment Viewer" --assignee <AAD-ENTITY-ID> --scope $AKS_ID
## Use Azure RBAC for Kubernetes Authorization with `kubectl`

az aks get-credentials -g MyResourceGroup -n MyManagedCluster
kubectl get nodes
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code AAAAAAAAA to authenticate.
## Use Azure RBAC for Kubernetes Authorization with `kubelogin`

## Clean up

az role assignment list --scope $AKS_ID --query [].id -o tsv
az role assignment delete --ids <LIST OF ASSIGNMENT IDS>
az role definition delete -n "AKS Deployment Viewer"
az group delete -n MyResourceGroup
## Next steps
