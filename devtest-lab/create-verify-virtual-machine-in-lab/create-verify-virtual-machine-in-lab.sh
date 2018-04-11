resourceGroupName='<Resource group in which lab exists>'
location='<Location in which the lab exists>'
labName="<Name of the lab>"
vmName="<Name for the VM>"
vmImageName="<Name of the image. For example: Ubuntu Server 16.04 LTS>"
vmSize="<Size of the image. For example: Standard_DS1_v2>"

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a VM from a marketplace image with ssh authentication
az lab vm create 
	--lab-name $labName 
	--resource-group $resourceGroupName
	--name $vmName 
	--image $vmImageName
	--image-type gallery 
	--size $vmSize
	--authentication-type  ssh 
	--generate-ssh-keys 
	--ip-configuration public

# Verify that the VM is available
az lab vm show 
	--lab-name sampleLabName 
	--name sampleVMName 
	--resource-group sampleResourceGroup 
	--expand 'properties($expand=ComputeVm,NetworkInterface)' 
	--query '{status: computeVm.statuses[0].displayStatus, fqdn: fqdn, ipAddress: networkInterface.publicIpAddress}'