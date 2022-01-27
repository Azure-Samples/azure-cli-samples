 # Passed validation in Cloud Shell on 1/27/2022

let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-vmss-rg-$randomIdentifier"
tags="use-data-disks-vmss"
image="UbuntuLTS"
scaleSet="msdocs-scaleSet-$randomIdentifier"
upgradePolicyMode="automatic"
instanceCount="2"
login="azureuser"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a scale set
# Network resources such as an Azure load balancer are automatically created
# Two data disks are created and attach - a 64Gb disk and a 128Gb disk
az vmss create --resource-group $resourceGroup --name $scaleSet --image $image --upgrade-policy-mode $upgradePolicyMode --instance-count $instanceCount --admin-username $login --generate-ssh-keys   --data-disk-sizes-gb 64 128

# Attach an additional 128Gb data disk
az vmss disk attach --resource-group $resourceGroup --vmss-name $scaleSet --size-gb 128

# Install the Azure Custom Script Extension to run a script that prepares the data disks
az vmss extension set --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript --resource-group $resourceGroup --vmss-name $scaleSet --settings '{"fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate_nginx.sh"],"commandToExecute":"./automate_nginx.sh"}'

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
