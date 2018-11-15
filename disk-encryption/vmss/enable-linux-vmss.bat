@rem - Enable disk encryption on Linux VMSS using CLI 2.0 
@echo off
if "%1"=="" goto usage
if "%2"=="" goto usage
if "%3"=="" goto usage
if "%4"=="" goto usage
if "%5"=="" goto usage
if "%6"=="" goto usage
if "%7"=="" goto usage
set ade_resource_group_name="%1"
set ade_location="%2"
set ade_vmss_name="%3"
set ade_image="%4"
set ade_instance_count=%5
set ade_username="%6"
set ade_password="%7"
set ade_keyvault="%8"
set ade_kek="%9"

echo "Creating resource group, virtual machine scale set, attaching disk, and updating instances..."
call az account show
call az group create -n %ade_resource_group_name% -l %ade_location%
call az vmss create -g %ade_resource_group_name% -n %ade_vmss_name% --instance-count %ade_instance_count% --image %ade_image% --admin-username %ade_username% --admin-password %ade_password%
call az vmss disk attach -g %ade_resource_group_name% -n %ade_vmss_name% --size-gb 5 --lun 3
call az vmss update-instances -g %ade_resource_group_name% -n %ade_vmss_name% --instance-ids *
echo "Waiting for VM to spin up and for waagent to start and set up udev naming rules..."
timeout /t 300

echo "Displaying IP adress and port number to use for any future SSH connection..."
call az vmss list-instance-connection-info -g %ade_resource_group_name% -n %ade_vmss_name%

echo "Formatting and mounting attached disk via Custom Script Extension..."
call az vmss extension set --name CustomScript --publisher Microsoft.Azure.Extensions --resource-group %ade_resource_group_name% --vmss-name %ade_vmss_name% --settings "{'fileUris': ['https://raw.githubusercontent.com/Azure-Samples/azure-cli-samples/master/disk-encryption/vmss/prepdisk.sh'], 'commandToExecute':'./prepdisk.sh'}"
call az vmss update-instances -g %ade_resource_group_name% -n %ade_vmss_name% --instance-ids *
echo "Waiting for format and mount operation to complete..."
timeout /t 300

echo "Enabling encryption for data disks..."
rem kek 
if "%ade_kek%"=="" goto nokek
call az vmss encryption enable -g %ade_resource_group_name% -n %ade_vmss_name% --disk-encryption-keyvault %ade_keyvault% --key-encryption-key %ade_kek% --volume-type DATA
goto updateinstances
:nokek
call az vmss encryption enable -g %ade_resource_group_name% -n %ade_vmss_name% --disk-encryption-keyvault %ade_keyvault% --volume-type DATA
:updateinstances
call az vmss update-instances -g %ade_resource_group_name% -n %ade_vmss_name% --instance-ids *

echo "Polling status for 15 minutes..."
for /l %%i in (1, 1, 30) do (
   call az vmss encryption show -g %ade_resource_group_name% -n %ade_vmss_name%
   timeout /t 30
)

goto done

:usage 
echo usage: enable-linux-vmss.bat [resource-group-name] [location] [vmss-name] [image] [instance-count] [username] [password] [ade-keyvault-id] [optional:ade-kek-url]
echo     [ade-keyvault-id] format:
echo       /subscriptions/[subid-guid]/resourceGroups/[rg-name]/providers/Microsoft.KeyVault/vaults/[vault-name]
echo  
echo     [ade-kek-url] format:  
echo       https://[vault-name].vault.azure.net:443/keys/[key-name]/[version]

:done