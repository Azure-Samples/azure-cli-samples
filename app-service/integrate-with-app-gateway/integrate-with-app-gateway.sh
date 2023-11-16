#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Integrate App Service with Application Gateway
#
# This sample script creates an Azure App Service web app,
# an Azure Virtual Network and an Application Gateway. 
# It then restricts the traffic for the web app to only
# originate from the Application Gateway subnet.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="integrate-with-app-gateway.sh"
vNet="msdocs-app-service-vnet-$randomIdentifier"
subnet="msdocs-app-service-subnet-$randomIdentifier"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"
appGateway="msdocs-app-gateway-$randomIdentifier"
publicIpAddress="msdocs-public-ip-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create network resources
az network vnet create --resource-group $resourceGroup --name $vNet --location "$location" --address-prefix 10.0.0.0/16 --subnet-name $subnet --subnet-prefix 10.0.1.0/24

az network public-ip create --resource-group $resourceGroup --location "$location" --name $publicIpAddress --dns-name $webapp --sku Standard --zone 1

# Create an App Service plan in `S1` tier
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku S1

# Create a web app.
echo "Creating $webapp"
az webapp create --name $webapp --resource-group $resourceGroup --plan $appServicePlan

appFqdn=$(az webapp show --name $webapp --resource-group $resourceGroup --query defaultHostName -o tsv)

# Create an Application Gateway
az network application-gateway create --resource-group $resourceGroup --name $appGateway --location "$location" --vnet-name $vNet --subnet $subnet --min-capacity 2 --sku Standard_v2 --http-settings-cookie-based-affinity Disabled --frontend-port 80 --http-settings-port 80 --http-settings-protocol Http --public-ip-address $publicIpAddress --servers $appFqdn --priority 1

az network application-gateway http-settings update --resource-group $resourceGroup --gateway-name $appGateway --name appGatewayBackendHttpSettings --host-name-from-backend-pool

# Apply Access Restriction to Web App
az webapp config access-restriction add --resource-group $resourceGroup --name $webapp --priority 200 --rule-name gateway-access --subnet $subnet --vnet-name $vNet

# Get the App Gateway Fqdn
az network public-ip show --resource-group $resourceGroup --name $publicIpAddress --query {AppGatewayFqdn:dnsSettings.fqdn} --output table
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
