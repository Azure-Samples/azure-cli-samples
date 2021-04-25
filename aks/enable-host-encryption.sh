FEATURENAME="EncryptionAtHost"
PROVIDERNAMESPACE="Microsoft.Compute"
RESOURCE_GROUP=myResourceGroup
S=Standard_DS2_v2
L=westus2
CLUSTER_NAME=myAKSCluster
## Before you begin

Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
# Install the aks-preview extension
az extension add --name aks-preview
## Use host-based encryption on new clusters (preview)

az aks create --name myAKSCluster --resource-group $RESOURCE_GROUP -s $S -l $L
## Use host-based encryption on existing clusters (preview)

az aks nodepool add --name hostencrypt --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP -s $S -l $L
## Next steps
