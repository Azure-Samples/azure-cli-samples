#!/bin/bash
# Passed validation in Cloud Shell on 1/27/2022

# <FullScript> 
# Install applications into a virtual machine scale set

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-vmss-rg-$randomIdentifier"
tag="install-apps-vmss"
image="Ubuntu2204"
scaleSet="msdocs-scaleSet-$randomIdentifier"
upgradePolicyMode="automatic"
instanceCount="2"
login="azureuser"
nlbWebRule="msdocs-nlb-web-rule-vmss"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a scale set
# Network resources such as an Azure load balancer are automatically created
echo "Creating $scaleSet with $instanceCount instances"
az vmss create --resource-group $resourceGroup --name $scaleSet --image $image --upgrade-policy-mode $upgradePolicyMode --instance-count $instanceCount --admin-username $login --generate-ssh-keys

# Install the Azure Custom Script Extension to run an install script
echo "Installing a basic Nginx webserver"
az vmss extension set --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript --resource-group $resourceGroup --vmss-name $scaleSet --settings '{"fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate_nginx.sh"],"commandToExecute":"./automate_nginx.sh"}'

# Create a load balancer rule to allow web traffic to reach VM instances
az network lb rule create --resource-group $resourceGroup --name $nlbWebRule --lb-name $scaleSet"LB" --backend-pool-name $scaleSet"LBBEPool" --backend-port 80 --frontend-ip-name loadBalancerFrontEnd --frontend-port 80 --protocol tcp

# Output the public IP address to access the site in a web browser
az network public-ip show --resource-group $resourceGroup --name $scaleSet"LBPublicIP" --query [ipAddress] --output tsv
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
