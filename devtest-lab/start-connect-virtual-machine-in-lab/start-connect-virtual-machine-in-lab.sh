resourceGroupName='<Resource group in which lab exists>'
labName="<Name of the lab>"
vmName="<Name for the VM>"

# Start the VM
az lab vm start 
	--lab-name $labName
	--name $vmName 
	--resource-group $resourceGroupName
