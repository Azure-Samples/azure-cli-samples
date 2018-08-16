# Azure Disk Encryption for VMSS Linux Data Disks

This script demonstrates how to script the CLI from a batch file to encrypt data disks on a Linux VMSS.   Although written as a batch file, similar steps can be performed from bash. 

## Operating environment
* [Install Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

## Important notes
Be aware this script accesses resources in your current default subscription.  To avoid polluting the wrong subscription with these resources, it is suggested to quickly check and make sure the correct subscription is being used:

```bash
az account show
```

# More information
* [Azure Disk Encryption for Windows and Linux IaaS VMs](https://azure.microsoft.com/en-us/documentation/articles/azure-security-disk-encryption/)
