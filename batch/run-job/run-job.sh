# test
#!/bin/bash
# Passed validation in Cloud Shell on 5/24/2022

# <FullScript>
# Run a job and tasks with Azure Batch

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
[[ "$RESOURCE_GROUP" == '' ]] && resourceGroup="msdocs-batch-rg-$randomIdentifier" || resourceGroup="${RESOURCE_GROUP}"
tag="run-job"
storageAccount="msdocsstorage$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a general-purpose storage account in your resource group.
echo "Creating $storageAccount"
az storage account create --resource-group $resourceGroup --name $storageAccount --location "$location" --sku Standard_LRS

# Create a Batch account.
echo "Creating $batchAccount"
az batch account create --name $batchAccount --storage-account $storageAccount --resource-group $resourceGroup --location "$location"

# Authenticate against the account directly for further CLI interaction.
az batch account login --name $batchAccount --resource-group $resourceGroup --shared-key-auth

# Create a new Linux pool with a virtual machine configuration. 
az batch pool create --id mypool --vm-size Standard_A1 --target-dedicated 2 --image canonical:ubuntuserver:18_04-lts-gen2 --node-agent-sku-id "batch.node.ubuntu 18.04"

# Create a new job to encapsulate the tasks that are added.
az batch job create --id myjob --pool-id mypool

# Add tasks to the job. Here the task is a basic shell command.
az batch task create --job-id myjob --task-id task1 --command-line "/bin/bash -c 'printenv AZ_BATCH_TASK_WORKING_DIR'"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
