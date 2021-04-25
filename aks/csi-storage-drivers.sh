## Limitations

az feature register --namespace "Microsoft.ContainerService" --name "EnableAzureDiskFileCSIDriver"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableAzureDiskFileCSIDriver')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
# Install the aks-preview extension
az extension add --name aks-preview
## Create a new cluster that can use CSI storage drivers

# Create an Azure resource group
az group create --name myResourceGroup --location canadacentral
# Create an AKS-managed Azure AD cluster
az aks create -g MyResourceGroup -n MyManagedCluster --network-plugin azure  --aks-custom-headers EnableAzureDiskFileCSIDriver=true
## Next steps
