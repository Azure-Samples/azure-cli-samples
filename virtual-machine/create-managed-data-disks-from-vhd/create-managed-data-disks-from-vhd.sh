# Verified per Raman Kumar as of 2/23/2022

# <FullScript>
#Provide the subscription Id
subscriptionId="<subscriptionId>"

#Provide the name of your resource group.
#Ensure that resource group is already created 
resourceGroupName=myResourceGroupName

#Provide the name of the Managed Disk
diskName=myDiskName

#Provide the size of the disks in GB. It should be greater than the VHD file size.
diskSize=128


#Provide the URI of the VHD file that will be used to create Managed Disk. 
# VHD file can be deleted as soon as Managed Disk is created.
# e.g. https://contosostorageaccount1.blob.core.windows.net/vhds/contosovhd123.vhd 
vhdUri=https://contosostorageaccount1.blob.core.windows.net/vhds/contosoumd78620170425131836.vhd

#Provide the storage type for the Managed Disk. Premium_LRS or Standard_LRS.
storageType=Premium_LRS


#Provide the Azure location (e.g. westus) where Managed Disk will be located. 
#The location should be same as the location of the storage account where VHD file is stored.
#Get all the Azure location supported for your subscription using command below:
#az account list-locations
location=westus

#If you're creating an OS disk, uncomment the following lines and replace the values
#osType = 'yourOSType' #Acceptable values are either Windows or Linux
#hyperVGeneration = 'yourHyperVGen' #Acceptable values are either v1 or v2

#Set the context to the subscription Id where Managed Disk will be created
az account set --subscription $subscriptionId

#Create the Managed disk from the VHD file 
#If you're creating an OS disk, add the following: --os-type $osType -hyper-v-generation $hyperVGeneration 
az disk create --resource-group $resourceGroupName --name $diskName --sku $storageType --location $location --size-gb $diskSize --source $vhdUri
# </FullScript>
