#!/bin/bash
set -e

# See ./README.md for notes
# Please use latest version of AZ CLI
# Enable HTTPS, Front Door managed cert is not possible currently 😢 So have to have to upload cert to Key Vault
# Azure DNS public zone must already exist for domain name
# Follow the steps in this article to give Front Door access to KV: 
#  https://docs.microsoft.com/en-us/azure/frontdoor/front-door-custom-domain-https#option-2-use-your-own-certificate
# Complete the CSR process in Key Vault before running this script:
#  https://docs.microsoft.com/en-us/azure/key-vault/certificates/create-certificate-signing-request?tabs=azure-portal#add-certificates-in-key-vault-issued-by-non-partnered-cas


# Hashing Username for UID instead of using $RANDOM so that this script is idempotent
uid=$(echo -n $USER | openssl dgst -sha256) ; uid=${uid:9:8}
location='AustraliaEast'
loc='aue'
rg="frontdoor-$uid-rg"
echo $rg
tags=('sample=deploy-custom-domain' 'repo=Azure-Samples/azure-cli-samples')

domainName='contoso.com'
storage="fd$uid$loc"

frontDoor="frontdoor-$uid"
frontDoorFrontEnd='contoso'

ttl=300
kv="frontdoor-$loc-kv"
kvSecretName='frontdoor-csr'


# RESOURCE GROUP
az group create -n $rg -l $location --tags $tags


# STORAGE ACCOUNT
az storage account create -n $storage -g $rg -l $location --sku Standard_LRS --kind StorageV2

# Make Storage Account a SPA
az storage blob service-properties update --account-name $storage --static-website \
    --index-document 'index.html' --404-document 'index.html' 

# Upload index.html
az storage blob upload --account-name $storage -f ./index.html -c '$web' -n 'index.html'

# Get the URL to use as the Origin URL on the Front Door backend
spaUrl=$( az storage account show -n $storage --query 'primaryEndpoints.web' -o tsv )

# Remove 'https://' and trailing '/' 🙄
spaUrl=${spaUrl/https:\/\//} ; spaUrl=${spaUrl/\//}
echo $spaUrl


# FRONT DOOR
frontDoorId=$( az network front-door create -n $frontDoor -g $rg --tags $tags --accepted-protocols Http Https --backend-address $spaUrl --query 'id' -o tsv )


# AZURE DNS
# Apex hostname on contoso.com
# Create an Alias DNS recordset
az network dns record-set a create -n "@" -g $rg --zone-name $domainName --if-none-match --target-resource $frontDoorId --ttl $ttl

# Create the domain verify CNAME
az network dns record-set cname set-record -g $rg --zone-name $domainName --if-none-match --record-set-name "afdverify.$domainName" --cname "afdverify.$frontDoor.azurefd.net" --ttl $ttl


# FRONT DOOR FRONT END
# Create a frontend for the custom domain
az network front-door frontend-endpoint create --front-door-name $frontDoor --host-name $domainName \
    --name $frontDoorFrontEnd -g $rg --session-affinity-enabled 'Disabled'

# Update the default routing rule to include the new frontend
az network front-door routing-rule update --front-door-name $frontDoor -n 'DefaultRoutingRule' -g $rg \
    --caching 'Enabled' --accepted-protocols 'HttpsOnly' \
    --frontend-endpoints 'DefaultFrontendEndpoint' $frontDoorFrontEnd

# Create http redirect to https routing rule
az network front-door routing-rule create -f $frontDoor -g $rg -n 'httpRedirect' \
    --frontend-endpoints $frontDoorFrontEnd --accepted-protocols 'Http' --route-type 'Redirect' \
    --patterns '/*' --redirect-protocol 'HttpsOnly'

# Update the default routing rule to include the new frontend
az network front-door routing-rule update --front-door-name $frontDoor -n 'DefaultRoutingRule' -g $rg \
    --caching 'Enabled' --frontend-endpoints 'DefaultFrontendEndpoint' $frontDoorFrontEnd

# get KV id
kvId=$( az keyvault show -n $kv -g $rg --query 'id' -o tsv )

# Enable HTTPS
az network front-door frontend-endpoint enable-https --front-door-name $frontDoor --name $frontDoorFrontEnd -g $rg \
    --certificate-source 'AzureKeyVault' --vault-id $kvId --secret-name $kvSecretName


echo "https://$frontDoor.azurefd.net"
echo "http://$domainName"
echo "https://$domainName"
