#!/bin/bash
# Passed validation in Cloud Shell on 1/27/2022

# <FullScript>
# Automatically scale a virtual machine scale set

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-vmss-rg-$randomIdentifier"
tag="auto-scale-host-metrics-vmss"
image="Ubuntu2204"
scaleSet="msdocs-scaleSet-$randomIdentifier"
upgradePolicyMode="automatic"
instanceCount="2"
login="azureuser"
autoscale="autoscale"
minCount="2"
maxCount="10"
count="2"
scaleOut="3"
scaleIn="1"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a scale set
# Network resources such as an Azure load balancer are automatically created
echo "Creating $scaleSet with $instanceCount instances"
az vmss create --resource-group $resourceGroup --name $scaleSet --image $image --upgrade-policy-mode $upgradePolicyMode --instance-count $instanceCount --admin-username $login --generate-ssh-keys

# Define an autoscale profile
# The following script sets the default, and minimum, capacity of *2* VM instances, and a maximum of *10*
echo "Setting an autoscale profile with the default, and minimum, capacity of 2 VM instances, and a maximum of 10"
az monitor autoscale create --resource-group $resourceGroup --resource=$scaleSet --resource-type Microsoft.Compute/virtualMachineScaleSets --name $autoscale --min-count $minCount --max-count $maxCount --count $count

# Create a rule to autoscale out
# The following script increases the number of VM instances in a scale set when the average CPU load
# is greater than 70% over a 5-minute period.
# When the rule triggers, the number of VM instances is increased by three.
echo "Creating an autoscale out rule"
az monitor autoscale rule create --resource-group $resourceGroup --autoscale-name $autoscale --condition "Percentage CPU > 70 avg 5m" --scale out $scaleOut

# Create a rule to autoscale in
# The following script decreases the number of VM instances in a scale set when the average CPU load 
# then drops below 30% over a 5-minute period
echo "Creating an autoscale in rule"
az monitor autoscale rule create --resource-group $resourceGroup --autoscale-name $autoscale --condition "Percentage CPU < 30 avg 5m" --scale in $scaleIn
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y

# The script is used in the following file, adding or removing lines may require you update the range value in this files
# articles\virtual-machine-scale-sets\tutorial-autoscale-cli.md
