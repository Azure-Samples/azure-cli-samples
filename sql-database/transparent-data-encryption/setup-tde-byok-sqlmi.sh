# You will need an existing Managed Instance as a prerequisite for completing this script.
# See https://docs.microsoft.com/azure/sql-database/scripts/sql-database-create-configure-managed-instance-cli

# login to your Azure account
az login

# set the subscription context for the Azure account
az account set -s $subscriptionID


# 1. Create Resource and setup Azure Key Vault (skip if already done)

# create Resource group (name the resource and specify the location)
$location = "westus2" # specify the location
$resourcegroup = "MyRG" # specify a new RG name
az group create \
   --name $resourceGroup \
   --location $location

# create new Azure Key Vault with a globally unique VaultName and soft-delete option turned on:
$vaultname = "MyKeyVault" # specify a globally unique VaultName
az keyvault create --name $vaultname \
    --resource-group $resourcegroup \
    --enable-soft-delete true \
    --location $location

# authorize Managed Instance to use the AKV (wrap/unwrap key and get public part of key, if public part exists): 
$objectid = (Set-AzSqlInstance -ResourceGroupName  -Name  -AssignIdentity).Identity.PrincipalId

$objectid = az sql mi show --name "MyManagedInstance" \
    --resource-group $resourcegroup \
    -o json
    --query [0].identity.principalid

az keyvault set-policy --name $vaultname \
    --key-permissions get, unwrapKey, wrapKey \
    --object-id $objectid
#-BypassObjectIdValidation

az sql mi update [--add]
                 [--admin-password]
                 [--assign-identity]
                 [--capacity]
                 [--force-string]
                 [--ids]
                 [--license-type {BasePrice, LicenseIncluded}]
                 [--name "MyManagedInstance"
                 [--no-wait]
                 [--proxy-override {Default, Proxy, Redirect}]
                 [--public-data-endpoint-enabled {false, true}]
                 [--remove]
                 [--resource-group $resourcegroup
                 [--set]
                 [--storage]
                 [--subscription]

# allow access from trusted Azure services: 
Update-AzKeyVaultNetworkRuleSet -VaultName  -Bypass AzureServices
az keyvault network-rule add --name $vaultname
                             [--ip-address]
                             [--resource-group]
                             [--subnet]
                             [--subscription]
                             [--vnet-name]

# turn the network rules ON by setting the default action to Deny: 
Update-AzKeyVaultNetworkRuleSet -VaultName  -DefaultAction Deny
az keyvault network-rule add --name $vaultname
                             [--ip-address]
                             [--resource-group]
                             [--subnet]
                             [--subscription]
                             [--vnet-name]


# 2. Provide TDE Protector key (skip if already done)

# the recommended way is to import an existing key from a .pfx file. Replace "<PFX private key password>" with the actual password below:
$keypath = "c:\some_path\mytdekey.pfx" # Supply your .pfx path and name
$securepfxpwd = ConvertTo-SecureString -String "<PFX private key password>" -AsPlainText -Force 
$key = Add-AzKeyVaultKey -VaultName  -Name  -KeyFilePath $keypath -KeyFilePassword $securepfxpwd

az keyvault key create --name "MyTDEKey"
                       --vault-name $vaultname
                       [--curve {P-256, P-256K, P-384, P-521}]
                       [--disabled {false, true}]
                       [--expires]
                       [--kty {EC, EC-HSM, RSA, RSA-HSM, oct}]
                       [--not-before]
                       [--ops {decrypt, encrypt, sign, unwrapKey, verify, wrapKey}]
                       [--protection {hsm, software}]
                       [--size]
                       [--subscription]
                       [--tags]

# ...or get an existing key from the vault:
$key = az keyvault key show --name "MyTDEKey" \
    --vault-name $vaultname \
    -o json
    --query [0].value

# alternatively, generate a new key directly in Azure Key Vault (recommended for test purposes only - uncomment below):
$key = az keyvault key create --name "MyTDEKey" \
    --vault-name $vaultname \
    --size 2048 \
    -o json --query [0].value


# 3. Set up BYOK TDE on Managed Instance:

# assign the key to the Managed Instance:
az sql mi key create --kid $key \
    --managed-instance "MyManagedInstance" \
    --resource-group $resourcegroup

# set TDE operation mode to BYOK: 
az sql mi tde-key set --server-key-type AzureKeyVault \
    --kid $key \
    --managed-instance "MyManagedInstance" \
    --resource-group $resourcegroup