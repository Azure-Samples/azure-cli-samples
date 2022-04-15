#!/bin/bash

# exit on error
set -e

# IMPORTANT
# Custom domain name must be created and set as environment variable CUSTOM_DOMAIN_NAME
# CNAMES must be created in DNS
# See ./README.md for notes
# Please use latest version of AZ CLI

# <FullScript>
# Deploy a Custom Domain name and TLS certificate on an Azure Front Door front-end.

# VARIABLES
# Change these hardcoded values if required

let "randomIdentifier=$RANDOM*$RANDOM"
location='AustraliaEast'
resourceGroup="msdocs-frontdoor-rg-$randomIdentifier"
tag='deploy-custom-domain'

storage="msdocsafd$randomIdentifier"

frontDoor="msdocs-frontdoor-$randomIdentifier"
frontDoorFrontEnd='www-contoso'

if [ "$CUSTOM_DOMAIN_NAME" == '' ]; 
   then echo -e "\033[33mCUSTOM_DOMAIN_NAME environment variable is not set. Front Door will be created but custom frontend will not be configured because custom domain name not provided. Try:\n\n    CUSTOM_DOMAIN_NAME=www.contoso.com ./deploy-custom-domain.sh\n\nSee Readme for details.\033[0m"
fi

# Resource group
az group create -n $resourceGroup -l $location --tags $tag


# Storage account to host SPA
az storage account create -n $storage -g $resourceGroup -l $location --sku Standard_LRS --kind StorageV2

# Turn no Static Website feature
az storage blob service-properties update --account-name $storage --static-website \
    --index-document 'index.html' --404-document 'index.html' 

# Upload index.html
az storage blob upload --account-name $storage -f ./index.html -c '$web' -n 'index.html'  --content-type 'text/html'

# Get the URL to use as the Origin URL on the Front Door backend
spaFQUrl=$( az storage account show -n $storage --query 'primaryEndpoints.web' -o tsv )

# Remove 'https://' and trailing '/'
spaUrl=${spaFQUrl/https:\/\//} ; spaUrl=${spaUrl/\//}


# Create Front Door

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
fi

# </FullScript>

echo "https://$frontDoor.azurefd.net"
echo "http://$CUSTOM_DOMAIN_NAME"
echo "https://$CUSTOM_DOMAIN_NAME"
echo "$spaFQUrl"


# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
