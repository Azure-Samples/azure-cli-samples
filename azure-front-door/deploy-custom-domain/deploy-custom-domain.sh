#!/bin/bash
set -e

# IMPORTANT
# 2 CNAMES must be created in DNS
# See ./README.md for notes
# Please use latest version of AZ CLI


# VARIABLES
# Change these hardcoded values if required

# Hashing Username for UID instead of using $RANDOM so that this script is idempotent
uid=$(echo -n $USER | openssl dgst -sha256)
uid=${uid:9:8}
location='AustraliaEast'
loc='aue'
rg="frontdoor-$uid-rg"
echo $rg
tags=('sample=deploy-custom-domain' 'repo=Azure-Samples/azure-cli-samples')

domainName='www.contoso.com'
storage="fd$uid$loc"

frontDoor="frontdoor-$uid"
frontDoorFrontEnd='www-contoso'


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
az network front-door create -n $frontDoor -g $rg --tags $tags --accepted-protocols Http Https --backend-address $spaUrl

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

# Enable HTTPS. This command will return quickly but provisioning can take up to an hour to complete
az network front-door frontend-endpoint enable-https \
    --front-door-name $frontDoor -n $frontDoorFrontEnd -g $rg 


echo "https://$frontDoor.azurefd.net"
echo "http://$domainName"
echo "https://$domainName"
