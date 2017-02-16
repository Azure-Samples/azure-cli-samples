rgname="capturerg"
vmname="capturevm"

# Get the NIC Id of the network interface attached to the VM
nicid=$(az vm show -g $rgname -n $vmname --query [networkProfile.networkInterfaces[0].id] -o tsv)

# For the NIC we got above, find the public IP address ID
pipid=$(az network nic show --ids $nicid --query [ipConfigurations[0].publicIpAddress.id] -o tsv)

# From the Public Ip address Id find the actual public ip
az network public-ip show --ids $pipid --query [ipAddress] -o tsv

# login to the VM
ssh myadmin@13.64.76.146

# Generalize the VM
sudo waagent -deprovision+user

# Deallocate
az vm deallocate -g $rgname -n $vmname

# Tell Azure that the VM has been generalized
az vm generalize -g $rgname -n $vmname

# Capture the VM which outputs a template. Note the OS Disk Uri and Os Disk type as we'll use it in the next command
az vm capture -g $rgname -n $vmname --vhd-name-prefix capturekay

# Create a new VM from the captured VM
az vm create -n "newvm" -g $rgname --admin-username myadmin --admin-password Password@1234 --public-ip-address "newimagevmkay" --image https://vhd14860889176058.blob.core.windows.net/system/Microsoft.Compute/Images/vhds/capturekay-osDisk.563aa2ca-bcfb-4e7d-8da1-45133add0ff6.vhd --authentication-type password --size Standard_DS2_v2 --custom-os-disk-type linux
