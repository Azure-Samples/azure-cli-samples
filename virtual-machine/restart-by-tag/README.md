# Restart VMs by Tag

This example creates a virtual machines in multiple resource groups with a given tag. Creation of the
virtual machines is done in parallel via `--no-wait` to illustrate how to start multiple VM creations
and to then wait for their collective completion.

After the virtual machines have been created, they are restarted using using two different query
mechanisms.

The first restarts the VMs using the query used to wait on their asynchronous creation.

```bash
az vm restart --ids $(az vm list --resource-group myResourceGroup --query "[].id" -o tsv)
```

The second uses a generic resource listing and query to fetch their IDs by tag.

```bash
az vm restart --ids $(az resource list --tag "restart-tag" --query "[?type=='Microsoft.Compute/virtualMachines'].id" -o tsv)
```

## To run this sample

Provision the VMs, wait for them to complete provisioning, then restart the VMs.

```bash
./provision.sh
./wait.sh
./restart.sh
```

## To tear down this sample
```bash
az group delete -n myResourceGroup --no-wait --yes
```