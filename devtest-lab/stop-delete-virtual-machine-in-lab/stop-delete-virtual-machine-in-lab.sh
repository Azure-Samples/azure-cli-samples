resourceGroupName='<Resource group in which lab exists>'
labName="<Name of the lab>"
vmName="<Name for the VM>"

# Stop the VM
az lab vm stop 
	--lab-name $labName
	--name $vmName 
	--resource-group $resourceGroupName

# Delete the VM
az lab vm delete 
	--lab-name $labName 
	--name $vmName
	--resource-group $resourceGroupName