#!/bin/bash

# exit on error
set -e

# See ./README.md for notes
# Please use latest version of AZ CLI
# Azure DNS public zone must already exist for domain name

# <FullScript>
# Deploy a Custom Domain name and TLS certificate at the apex (root) on an Azure Front Door front-end.

# VARIABLES
# Change these hardcoded values if required

let "randomIdentifier=$RANDOM*$RANDOM"

# Use resource group environment variable if set
if [ "$RESOURCE_GROUP" == '' ];  
    then
        resourceGroup="msdocs-frontdoor-rg-$randomIdentifier"
    else
        resourceGroup="${RESOURCE_GROUP}"
fi

location='AustraliaEast'
tag='deploy-custom-domain'

storage="msdocsafd$randomIdentifier"

frontDoor="msdocs-frontdoor-$randomIdentifier"
frontDoorFrontEnd='www-contoso'

ttl=300

if [ "$AZURE_DNS_ZONE_NAME" == '' ]; 
   then 
        echo -e "\033[33mAZURE_DNS_ZONE_NAME environment variable is not set. Front Door will be created but custom frontend will not be configured because custom domain name not provided. Try:\n\n    AZURE_DNS_ZONE_NAME=www.contoso.com AZURE_DNS_ZONE_RESOURCE_GROUP=contoso-dns-rg ./deploy-custom-apex-domain.sh\n\nSee Readme for details.\033[0m"
   else     
        if [ "$AZURE_DNS_ZONE_RESOURCE_GROUP" == '' ]; 
            then 
                # write error text
                echo -e "\033[31mAZURE_DNS_ZONE_RESOURCE_GROUP environment variable is not set. Provide the resource group for the Azure DNS Zone. Try:\n\n    AZURE_DNS_ZONE_NAME=www.contoso.com AZURE_DNS_ZONE_RESOURCE_GROUP=contoso-dns-rg ./deploy-custom-apex-domain.sh\n\nSee Readme for details.\033[0m"
                
                # write stderr and exit
                >&2 echo "AZURE_DNS_ZONE_RESOURCE_GROUP environment variable is not set."
                exit 1
    fi
fi

# Resource group
az group create -n $resourceGroup -l $location --tags $tag


# STORAGE ACCOUNT
az storage account create -n $storage -g $resourceGroup -l $location --sku Standard_LRS --kind StorageV2

# Make Storage Account a SPA
az storage blob service-properties update --account-name $storage --static-website \
    --index-document 'index.html' --404-document 'index.html' 

# Upload index.html
az storage blob upload --account-name $storage -f ./index.html -c '$web' -n 'index.html' --content-type 'text/html'

# Get the URL to use as the origin URL on the Front Door backend
spaFQUrl=$( az storage account show -n $storage --query 'primaryEndpoints.web' -o tsv )

# Remove 'https://' and trailing '/'
spaUrl=${spaFQUrl/https:\/\//} ; spaUrl=${spaUrl/\//}


# FRONT DOOR
frontDoorId=$( az network front-door create -n $frontDoor -g $resourceGroup --tags $tag --accepted-protocols Http Https --backend-address $spaUrl --query 'id' -o tsv )


if [ "$AZURE_DNS_ZONE_NAME" != '' ]; 
   then 

    # AZURE DNS
    # Apex hostname on contoso.com
    # Create an Alias DNS recordset
    az network dns record-set a create -n "@" -g $AZURE_DNS_ZONE_RESOURCE_GROUP --zone-name $AZURE_DNS_ZONE_NAME --target-resource $frontDoorId --ttl $ttl

    # Create the domain verify CNAME
    az network dns record-set cname set-record -g $AZURE_DNS_ZONE_RESOURCE_GROUP --zone-name $AZURE_DNS_ZONE_NAME --record-set-name "afdverify" --cname "afdverify.$frontDoor.azurefd.net" --ttl $ttl


    # FRONT DOOR FRONT END
    # Create a frontend for the custom domain
    az network front-door frontend-endpoint create --front-door-name $frontDoor --host-name $AZURE_DNS_ZONE_NAME \
        --name $frontDoorFrontEnd -g $resourceGroup --session-affinity-enabled 'Disabled'

    # Update the default routing rule to include the new frontend
    az network front-door routing-rule update --front-door-name $frontDoor -n 'DefaultRoutingRule' -g $resourceGroup \
        --caching 'Enabled' --accepted-protocols 'Https' \
        --frontend-endpoints 'DefaultFrontendEndpoint' $frontDoorFrontEnd

    # Create http redirect to https routing rule
    az network front-door routing-rule create -f $frontDoor -g $resourceGroup -n 'httpRedirect' \
        --frontend-endpoints $frontDoorFrontEnd --accepted-protocols 'Http' --route-type 'Redirect' \
        --patterns '/*' --redirect-protocol 'HttpsOnly'

    # Update the default routing rule to include the new frontend
    az network front-door routing-rule update --front-door-name $frontDoor -n 'DefaultRoutingRule' -g $resourceGroup \
        --caching 'Enabled' --frontend-endpoints 'DefaultFrontendEndpoint' $frontDoorFrontEnd


    # Enable HTTPS. This command will return quickly but provisioning can take up to an hour to complete
    az network front-door frontend-endpoint enable-https \
        --front-door-name $frontDoor -n $frontDoorFrontEnd -g $resourceGroup
fi

# </FullScript>

echo "https://$frontDoor.azurefd.net"
echo "http://$AZURE_DNS_ZONE_NAME"
echo "https://$AZURE_DNS_ZONE_NAME"
echo "$spaFQUrl"

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
