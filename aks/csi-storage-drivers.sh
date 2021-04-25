LOCATION=canadacentral
G=MyResourceGroup
N=MyManagedCluster
NETWORK_PLUGIN=azure 
AKS_CUSTOM_HEADERS=EnableAzureDiskFileCSIDriver=true
## Limitations

az feature register --namespace "Microsoft.ContainerService" --name "EnableAzureDiskFileCSIDriver"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableAzureDiskFileCSIDriver')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
# Install the aks-preview extension
az extension add --name aks-preview
## Create a new cluster that can use CSI storage drivers

# Create an Azure resource group
az group create --name myResourceGroup --location $LOCATION
# Create an AKS-managed Azure AD cluster
az aks create -g $G -n $N --network-plugin $NETWORK_PLUGIN --aks-custom-headers $AKS_CUSTOM_HEADERS
## Next steps
