# Verified per Raman Kumar as of 2/23/2022

# <FullScript>
#Provide the subscription Id of the subscription where snapshot exists
sourceSubscriptionId="<subscriptionId>"

#Provide the name of your resource group where snapshot exists
sourceResourceGroupName=mySourceResourceGroupName

#Provide the name of the snapshot
snapshotName=mySnapshotName

#Set the context to the subscription Id where snapshot exists
az account set --subscription $sourceSubscriptionId

#Get the snapshot Id 
snapshotId=$(az snapshot show --name $snapshotName --resource-group $sourceResourceGroupName --query [id] -o tsv)

#If snapshotId is blank then it means that snapshot does not exist.
echo 'source snapshot Id is: ' $snapshotId

#Provide the subscription Id of the subscription where snapshot will be copied to
#If snapshot is copied to the same subscription then you can skip this step
targetSubscriptionId=6492b1f7-f219-446b-b509-314e17e1efb0

#Name of the resource group where snapshot will be copied to
targetResourceGroupName=mytargetResourceGroupName

#Set the context to the subscription Id where snapshot will be copied to
#If snapshot is copied to the same subscription then you can skip this step
az account set --subscription $targetSubscriptionId

#Copy snapshot to different subscription using the snapshot Id
#We recommend you to store your snapshots in Standard storage to reduce cost. Please use Standard_ZRS in regions where zone redundant storage (ZRS) is available, otherwise use Standard_LRS
#Please check out the availability of ZRS here: https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy-zrs#support-coverage-and-regional-availability
az snapshot create --resource-group $targetResourceGroupName --name $snapshotName --source $snapshotId --sku Standard_LRS
# </FullScript>
