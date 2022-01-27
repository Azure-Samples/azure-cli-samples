#!/bin/bash
# Passed validation in Cloud Shell on 1/26/2022

let "randomIdentifier=$RANDOM*$RANDOM"
subcriptionId=$(az account show --query id -o tsv)
location="East US"
resourceGroup="msdocs-vmss-rg-$randomIdentifier"
tags="auto-scale-host-metrics-vmss"
image="UbuntuLTS"
scaleSet="msdocs-scaleSet-$randomIdentifier"
upgradePolicyMode="automatic"
instanceCount="2"
login="msdocsadminuser"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a scale set
# Network resources such as an Azure load balancer are automatically created
az vmss create \
  --resource-group $resourceGroup \
  --name $scaleSet \
  --image $image \
  --upgrade-policy-mode $upgradePolicyMode \
  --instance-count $instanceCount \
  --admin-username $login \
  --generate-ssh-keys

# Define auto scale rules
# These rules automatically scale up the number of VM instances by 3 instances when the average CPU load over a 5-minute
# window exceeds 70%
# The scale set then automatically scales in by 1 instance when the average CPU load over a 5-minute window drops below 30%

# Define an autoscale profile
# The following script sets the default, and minimum, capacity of *2* VM instances, and a maximum of *10*
az monitor autoscale create --resourceGroup $resourceGroup /
  --resource=$scaleSet /
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name autoscale \
  --min-count 2 \
  --max-count 10 \
  --count 2

# Create a rule to autoscale out
# The following script increases the number of VM instances in a scale set when the average CPU load
# is greater than 70% over a 5-minute period.
# When the rule triggers, the number of VM instances is increased by three.

az monitor autoscale rule create \
  --resource-group myResourceGroup \
  --autoscale-name autoscale \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 3



az monitor autoscale-settings create \
    --resource-group $resourcegroup_name \
    --name autoscale \
    --parameters '{"autoscale_setting_resource_name": "autoscale",
      "enabled": true,
      "location": "'$location_name'",
      "notifications": [],
      "profiles": [
        {
          "name": "autoscale by percentage based on CPU usage",
          "capacity": {
            "minimum": "2",
            "maximum": "10",
            "default": "2"
          },
          "rules": [
            {
              "metricTrigger": {
                "metricName": "Percentage CPU",
                "metricNamespace": "",
                "metricResourceUri": "/subscriptions/'$sub'/resourceGroups/'$resourcegroup_name'/providers/Microsoft.Compute/virtualMachineScaleSets/'$scaleset_name'",
                "metricResourceLocation": "'$location_name'",
                "timeGrain": "PT1M",
                "statistic": "Average",
                "timeWindow": "PT5M",
                "timeAggregation": "Average",
                "operator": "GreaterThan",
                "threshold": 70
              },
              "scaleAction": {
                "direction": "Increase",
                "type": "ChangeCount",
                "value": "3",
                "cooldown": "PT5M"
              }
            },
            {
              "metricTrigger": {
                "metricName": "Percentage CPU",
                "metricNamespace": "",
                "metricResourceUri": "/subscriptions/'$sub'/resourceGroups/'$resourcegroup_name'/providers/Microsoft.Compute/virtualMachineScaleSets/'$scaleset_name'",
                "metricResourceLocation": "'$location_name'",
                "timeGrain": "PT1M",
                "statistic": "Average",
                "timeWindow": "PT5M",
                "timeAggregation": "Average",
                "operator": "LessThan",
                "threshold": 30
              },
              "scaleAction": {
                "direction": "Decrease",
                "type": "ChangeCount",
                "value": "1",
                "cooldown": "PT5M"
              }
            }
          ]
        }
      ],
      "tags": {},
      "target_resource_uri": "/subscriptions/'$sub'/resourceGroups/'$resourcegroup_name'/providers/Microsoft.Compute/virtualMachineScaleSets/'$scaleset_name'"
    }'
