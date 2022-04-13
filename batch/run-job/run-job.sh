#!/bin/bash
# Failed validation in Cloud Shell on 4/7/2022

# <FullScript>
# Create a Batch account in Batch service mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-batch-rg-$randomIdentifier"
storageAccount="msdocsstorage$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"

# Create a resource group.
az group create --name $resourceGroup --location westeurope

# Create a general-purpose storage account in your resource group.
az storage account create \
    --resource-group $resourceGroup \
    --name $storageAccount \
    --location westeurope \
    --sku Standard_LRS

# Create a Batch account.
az batch account create \
    --name $batchAccount \
    --storage-account $storageAccount \
    --resource-group $resourceGroup \
    --location westeurope

# Authenticate against the account directly for further CLI interaction.
az batch account login \
    --name $batchAccount \
    --resource-group $resourceGroup \
    --shared-key-auth

# Create a new Linux pool with a virtual machine configuration. 
az batch pool create \
    --id mypool \
    --vm-size Standard_A1 \
    --target-dedicated 2 \
    --image canonical:ubuntuserver:18.04-LTS \
    --node-agent-sku-id "batch.node.ubuntu 18.04" # what is query to get correct update to --image and --node-agent-ski-id?


# Create a new job to encapsulate the tasks that are added.
az batch job create \
    --id myjob \
    --pool-id mypool

# Add tasks to the job. Here the task is a basic shell command.
az batch task create \
    --job-id myjob \
    --task-id task1 \
    --command-line "/bin/bash -c 'printenv AZ_BATCH_TASK_WORKING_DIR'"

# To add many tasks at once, specify the tasks
# in a JSON file, and pass it to the command. 
# For format, see https://github.com/Azure/azure-docs-cli-python-samples/blob/master/batch/run-job/tasks.json.
az batch task create \
    --job-id myjob \
    --json-file tasks.json

# Error
Cannot access JSON request file: tasks.json

# Update the job so that it is automatically
# marked as completed once all the tasks are finished.
az batch job set \
--job-id myjob \
--on-all-tasks-complete terminatejob

# Monitor the status of the job.
az batch job show --job-id myjob

# Monitor the status of a task.
az batch task show \
    --job-id myjob \
    --task-id task1
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
