#!/bin/bash
# Passed validation in Cloud Shell on 1/27/2022

# <FullScript>
# Create a single-zone virtual machine scale set

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-vmss-rg-$randomIdentifier"
tag="create-single-availability-zone-vmss"
image="Ubuntu2204"
scaleSet="msdocs-scaleSet-$randomIdentifier"
upgradePolicyMode="automatic"
instanceCount="2"
login="azureuser"
zones="1"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a scale set in Availability Zone 1
# This command also creates a 'Standard' SKU public IP address and load balancer
# For the Load Balancer Standard SKU, a Network Security Group and rules are also created
echo "Creating $scaleSet with $instanceCount instances"
az vmss create --resource-group $resourceGroup --name $scaleSet --image $image --upgrade-policy-mode $upgradePolicyMode --instance-count $instanceCount --admin-username $login --generate-ssh-keys --zones $zones

# Apply the Custom Script Extension that installs a basic Nginx webserver
echo "Installing a basic Nginx webserver"
az vmss extension set --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript --resource-group $resourceGroup --vmss-name $scaleSet --settings '{"fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate_nginx.sh"],"commandToExecute":"./automate_nginx.sh"}'

# Output the public IP address to access the site in a web browser
echo "Displaying the public IP address"
az network public-ip show --resource-group $resourceGroup --name $scaleSet"LBPublicIP" --query [ipAddress] --output tsv
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
