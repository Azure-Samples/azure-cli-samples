# Volume backup configuration

![Azure Public Test Date](https://azurequickstartsservice.blob.core.windows.net/badges/netappfiles/volume-backup/PublicLastTestDate.svg)
![Azure Public Test Result](https://azurequickstartsservice.blob.core.windows.net/badges/netappfiles/volume-backup/PublicDeployment.svg)

![Best Practice Check](https://azurequickstartsservice.blob.core.windows.net/badges/netappfiles/volume-backup/BestPracticeResult.svg)
![Cred Scan Check](https://azurequickstartsservice.blob.core.windows.net/badges/netappfiles/volume-backup/CredScanResult.svg)

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://shell.azure.com/)

Configures backup policies and manages volume backups.

## Sample overview and deployed resources

This sample demonstrates how to:

- Create the required Azure NetApp Files resources
- Configure the service according to best practices  
- Clean up resources when done

The following resources are deployed as part of this sample:

- Resource Group
- NetApp Account
- Virtual Network and Subnet
- NetApp Volume
- Backup Policy

## Prerequisites

- Azure CLI installed and authenticated
- Valid Azure subscription with NetApp Files enabled
- Appropriate permissions to create resources

## Usage

```bash
# Make the script executable
chmod +x volume-backup.sh

# Run the script
./volume-backup.sh
```

## Parameters

The script uses random identifiers for resource names to avoid conflicts. You can modify the variables at the top of the script to customize:

- `location`: Azure region for deployment
- `resourceGroup`: Name prefix for the resource group
- Service-specific parameters

## Clean up resources

Uncomment the cleanup section at the end of the script to delete all created resources:

```bash
# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
```

## Sample output

The script provides detailed output showing:
- Resource creation progress
- Configuration details
- Resource identifiers for future reference

## Notes

- This sample follows Azure CLI Samples repository conventions
- All resources are created with random identifiers to avoid naming conflicts
- Resources are tagged for easy identification
- Error handling and validation are included

For more information about Azure NetApp Files, see:
- [Azure NetApp Files documentation](https://docs.microsoft.com/azure/azure-netapp-files/)
- [Azure NetApp Files CLI reference](https://docs.microsoft.com/cli/azure/netappfiles)

`Tags: Azure NetApp Files, NFS, Storage, High Performance, Enterprise`
