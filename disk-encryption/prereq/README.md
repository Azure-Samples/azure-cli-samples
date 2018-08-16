# Azure Disk Encryption Prerequisites Script

The prereq.sh script is designed to make it easier for anyone using the Azure CLI on Linux to enable Azure Disk Encryption (ADE) on Azure VM's by demonstrating how to automate the creation of the necessary prerequisites.

## Operating environment
* Bash (tested on Ubuntu 16.04 LTS) 
* [Install Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)]
* [Install jq](https://stedolan.github.io/jq/download/)

## Important notes
Be aware this script will create resources in your current default subscription.  To avoid polluting the wrong subscription with these resources, it is suggested to quickly check and make sure the correct subscription is being used:

```bash
az account show
```
For tight control over how and where each disk encryption prerequisite will be created, several parameters are available.  A detailed description of each parameter is available using the help option:
```bash
./prereq.sh --help 
```

## Quick Start

If you'd like the script to create prerequisites within a specific location (matching an existing VM in westus2 for example):
```bash
./prereq.sh --ade-location westus2
```

If you don't mind the script selecting an arbitrary location, no parameters are required:
```bash
./prereq.sh
```

Once the script completes, it will output the names and identifiers of each resource that it has created.  It logs these values to a file in a uniquely named subdirectory for future reference.  To restore these values as environment variables, navigate into that directory and run the following command:
```bash
source ./ade_env.sh 
```
The prerequisite environment variables (all starting with the prefix ADE) are now available for use in bash.  Various disk encryption scenarios can be experimented with. 

### Create a VM 
One thing the script does not do for you is create a test VM to be encrypted.  To continue with the below scenario, first create a VM from a stock gallery image corresonding to a supported Windows operating system or [Linux distribution](https://docs.microsoft.com/en-us/azure/security/azure-security-disk-encryption-faq#what-linux-distributions-does-azure-disk-encryption-support). The VM must reside in the same regional location as the Key Vault ($ADE_LOCATION) and optionally, within the same resource group ($ADE_RG_NAME).  

If you'd like, save the name of this VM into the following environment variable:
```bash
ADE_VM_NAME=your-new-vm-name-here
```

### Enabling Encryption Without AAD

By default this script will create necessary key vault resources and grant the platform the necessary access to the key vault for disk encryption scenarios.  This is all that is needed when enabling encryption without specifying any Azure Active Directory (AAD) parameters.

Key vault resources are created within a specific resource group container.  Deleting the resource group later will also delete the key vault resources.  


### Enabling Encryption With AAD 

The prerequisite script, when used with the --aad option will also generate the necessary Azure Active Directory (AAD) resources to enable encryption with AAD. 

In this scenario, the credentials of an AAD application are used from within the context of the VM to authenticate to key vault endpoints.  These credentials may take the form of either a client secret (password string), or an X509 certificate.  The commands to enable disk encryption will accept either authentication option.  
 
Please note that Azure AD is implemented as a global service and the AD application itself does not reside within a resource group container.  This means that when it comes time to delete an AD application later, it will not be deleted at the time of resource group deletion.  AD resources must be deleted separately. 

Here are are some further details explaining the differences between using client secrets and client certificates and the steps needed to use them once generated by this script:

### Client Secret 

The client secret is a password in string format that is stored in the log subfolder and that can also be made available as an environment variable. On throwaway test resources used for short lived demonstrations or experimentation, this risk may be acceptable.  In a production environment, this may not be acceptable.  Tight control over the creation, storage, and future access to this secret is warranted.

To enable encryption using client secret, see the documentation for [az vm encryption enable](https://docs.microsoft.com/en-us/cli/azure/vm/encryption?view=azure-cli-latest).

### Client Certificates 
As an alternative to using a client secret, this script demonstrates creating a self-signed certificate within keyvault that can be deployed to the VM.  The virtue of this technique is that the private key in the certificate is never handled by the administrator running the script and is not stored on the administrative console.  It is transferred from key vault to the VM, and is only referred to by its thumbprint within the administrative console. 

To enable encryption with AAD using certificates instead of client secrets, there are two main steps.

**First**, prior to encrypting the VM, add the self-signed certificate that lives in keyvault to the VM that you are targeting.  To do this, refer to the documentation for [az vm secret](https://docs.microsoft.com/en-us/cli/azure/vm/secret?view=azure-cli-latest#az-vm-secret-add).

**Second**, now that the certificate resides on the VM, disk encryption can be started in a way that only requires passing the thumbprint of that certificate as documented for [az vm encryption enable](https://docs.microsoft.com/en-us/cli/azure/vm/encryption?view=azure-cli-latest).

# More information
* [Azure Disk Encryption for Windows and Linux IaaS VMs](https://azure.microsoft.com/en-us/documentation/articles/azure-security-disk-encryption/)
* [Powershell Azure Disk Encryption Prerequisite Setup](https://github.com/Azure/azure-powershell/blob/dev/src/ResourceManager/Compute/Commands.Compute/Extension/AzureDiskEncryption/Scripts/AzureDiskEncryptionPreRequisiteSetup.ps1)