#!/bin/bash
export AZURE_STORAGE_ACCOUNT=marsmastg001
export AZURE_STORAGE_ACCESS_KEY=eam2XpcO3zG+Jfy8c+cYnKPvNLhBKN4nxdoL7kAE4szPhsRHJtP6GazBrJeDST6Tyrzi0nQ4Z3NVzOiRi+xW+g==

# Create a resource group
az group create --name myResourceGroup --location eastus

# Create a container
az storage container create --name mycontainer

# Create sample text files
for i in `seq 1 3`; do
    hexdump -n 16 -v -e '/1 "%02X"' -e '/16 "\n"' /dev/urandom > container_size_sample_file_$i.txt
done

# Upload sample text files to container
az storage blob upload-batch --pattern "*.txt" --source . --destination mycontainer

# Calculate total size of container
bytes=`az storage blob list --container-name mycontainer --query "[*].[properties.contentLength]" --output tsv | paste --serial --delimiters=+ | bc`

# Display total bytes
echo "Total bytes in container: $bytes"

# Delete the sample files created by this script
rm container_size_sample_file_*.txt
