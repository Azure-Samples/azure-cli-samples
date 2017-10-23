#!/bin/bash

# Get managed applications from known resource group
az managedapp list --query "[?contains(resourceGroup,'DemoApp')]"

# Get ID of managed resource group
az managedapp list --query "[?contains(resourceGroup,'DemoApp')].{ managedResourceGroup:managedResourceGroupId }"

# Get virtual machines in the managed resource group
az resource list -g DemoApp6zkevchqk7sfq --query "[?contains(type,'Microsoft.Compute/virtualMachines')]"

# Get information about virtual machines in managed resource group
az vm list -g DemoApp6zkevchqk7sfq --query "[].{VMName:name,OSType:storageProfile.osDisk.osType,VMSize:hardwareProfile.vmSize}"

## Resize virtual machines in managed resource group
az vm resize --size Standard_D2_v2 --ids $(az vm list -g DemoApp6zkevchqk7sfq --query "[].id" -o tsv)