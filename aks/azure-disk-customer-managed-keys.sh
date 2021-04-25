## Limitations

## Prerequisites

## Create an Azure Key Vault instance

# Optionally retrieve Azure region short names for use on upcoming commands
az account list-locations
# Create new resource group in a supported Azure region
az group create -l myAzureRegionName -n myResourceGroup
## Create an instance of a DiskEncryptionSet

# Retrieve the Key Vault Id and store it in a variable
keyVaultId=$(az keyvault show --name myKeyVaultName --query "[id]" -o tsv)
## Grant the DiskEncryptionSet access to key vault

# Retrieve the DiskEncryptionSet value and set a variable
desIdentity=$(az disk-encryption-set show -n myDiskEncryptionSetName  -g myResourceGroup --query "[identity.principalId]" -o tsv)
## Create a new AKS cluster and encrypt the OS disk

# Retrieve the DiskEncryptionSet value and set a variable
diskEncryptionSetId=$(az disk-encryption-set show -n mydiskEncryptionSetName -g myResourceGroup --query "[id]" -o tsv)
## Encrypt your AKS cluster data disk(optional)

# Retrieve your Azure Subscription Id from id property as shown below
az account list
# Get credentials
az aks get-credentials --name myAksCluster --resource-group myResourceGroup --output table
## Next steps
