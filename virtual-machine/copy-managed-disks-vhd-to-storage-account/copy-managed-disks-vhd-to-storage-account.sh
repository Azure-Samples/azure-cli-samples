# Verified by Liam Kelly as of 12/08/2025

# <FullScript>
#Provide the subscription Id where managed disk is created
subscriptionId="<subscriptionId>"

#Provide the name of your resource group where managed disk is created
resourceGroupName=myResourceGroupName

#Provide the managed disk name 
diskName=myDiskName

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/azure/storage/storage-dotnet-shared-access-signature-part-1
sasExpiryDuration=3600

#Provide storage account name where you want to copy the underlying VHD file of the managed disk. 
storageAccountName=mystorageaccountname

#Name of the storage container where the downloaded VHD will be stored
storageContainerName=mystoragecontainername

#Provide the key of the storage account where you want to copy the VHD 
storageAccountKey=mystorageaccountkey

#Provide the name of the destination VHD file to which the VHD of the managed disk will be copied.
destinationVHDFileName=myvhdfilename.vhd

az account set --subscription $subscriptionId

sas=$(az disk grant-access --resource-group $resourceGroupName --name $diskName --duration-in-seconds $sasExpiryDuration --query "accessSAS" -o tsv)

az storage blob copy start --destination-blob $destinationVHDFileName --destination-container $storageContainerName --account-name $storageAccountName --account-key $storageAccountKey --source-uri $sas
# </FullScript>
