#!/bin/bash
export AZURE_STORAGE_ACCOUNT=<storage-account-name>
export AZURE_STORAGE_ACCESS_KEY=<storage-account-key>

# Create a resource group
az group create --name myResourceGroup --location eastus

# Create a container
az storage container create --name mycontainer

# Create sample text files
for i in `seq 1 3`; do
    hexdump -n 16 -v -e '/1 "%02X"' -e '/16 "\n"' /dev/urandom > container_size_sample_file_$i.txt
done

# Upload sample text files to container
az storage blob upload-batch --pattern "container_size_sample_file_*.txt" --source . --destination mycontainer

# Calculate total size of container
bytes=`az storage blob list --container-name mycontainer --query "[*].[properties.contentLength]" --output tsv | paste --serial --delimiters=+ | bc`

# Display total bytes
echo "Total bytes in container: $bytes"

# Delete the sample files created by this script
rm container_size_sample_file_*.txt
