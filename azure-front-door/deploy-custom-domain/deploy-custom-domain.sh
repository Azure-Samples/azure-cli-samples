#!/bin/bash
set -e

# IMPORTANT
# 2 CNAMES must be created in DNS
# See ./README.md for notes
# Please use latest version of AZ CLI

# <FullScript>
# Deploy a Custom Domain name and TLS certificate on an Azure Front Door front-end.

# VARIABLES
# Change these hardcoded values if required

# Pass custom domain name parameter as environment variable named CUSTOM_DOMAIN_NAME

# Hashing Username for UID instead of using $RANDOM so that this script is idempotent
let "randomIdentifier=$RANDOM*$RANDOM"
location='AustraliaEast'
resourceGroup="msdocs-frontdoor-rg-$randomIdentifier"
tag='deploy-custom-domain'

storage="msdocsafd$randomIdentifier"

frontDoor="msdocs-frontdoor-$randomIdentifier"
frontDoorFrontEnd='www-contoso'


# RESOURCE GROUP
az group create -n $resourceGroup -l $location --tags $tag


# STORAGE ACCOUNT
az storage account create -n $storage -g $resourceGroup -l $location --sku Standard_LRS --kind StorageV2

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
az network front-door create -n $frontDoor -g $resourceGroup --tags $tag --accepted-protocols Http Https --backend-address $spaUrl

if [ "$CUSTOM_DOMAIN_NAME" != '' ]; 
   then 
        # Create a frontend for the custom domain
        az network front-door frontend-endpoint create --front-door-name $frontDoor --host-name $CUSTOM_DOMAIN_NAME \
            --name $frontDoorFrontEnd -g $resourceGroup --session-affinity-enabled 'Disabled'

        # Update the default routing rule to include the new frontend
        az network front-door routing-rule update --front-door-name $frontDoor -n 'DefaultRoutingRule' -g $resourceGroup \
            --caching 'Enabled' --accepted-protocols 'HttpsOnly' \
            --frontend-endpoints 'DefaultFrontendEndpoint' $frontDoorFrontEnd

        # Create http redirect to https routing rule
        az network front-door routing-rule create -f $frontDoor -g $resourceGroup -n 'httpRedirect' \
            --frontend-endpoints $frontDoorFrontEnd --accepted-protocols 'Http' --route-type 'Redirect' \
            --patterns '/*' --redirect-protocol 'HttpsOnly'

        # Enable HTTPS. This command will return quickly but provisioning can take up to an hour to complete
        az network front-door frontend-endpoint enable-https \
            --front-door-name $frontDoor -n $frontDoorFrontEnd -g $resourceGroup
    else
        echo "Custom domain name frontend not created because environment variable CUSTOM_DOMAIN_NAME not provided"
fi

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
