#Provide the subscription Id
subscriptionId=6492b1f7-f219-446b-b509-314e17e1efb0

#Provide the name of your resource group
resourceGroupName=myResourceGroupName

#Provide the name of the Managed Disk
manageddiskName=myOSDiskName

#Provide the OS type
osType=linux

#Provide the name of the virtual machine
virtualMachineName=myVirtualMachineName

#Set the context to the subscription Id where Managed Disk exists and where VM will be created
az account set --subscription $subscriptionId

#Create VM by attaching existing managed disks as OS
#if managed disk exist in a different resource group then use managed disk Id instead of name of the disk 
#managedDiskId=$(az disk show --name managedDiskName --resource-group sourceResourceGroupName --query [id] -o tsv)

az vm create --name $virtualMachineName --resource-group $resourceGroupName --attach-os-disk $manageddiskName --os-type $osType