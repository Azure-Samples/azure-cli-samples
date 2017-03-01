# Restart VMs by Tag

This example creates a virtual machines in multiple resource groups with a given tag. Creation of the
virtual machines is done in parallel via `--no-wait` to illustrate how to start multiple VM creations
and to then wait for their collective completion.

After the virtual machines have been created, they are restarted using using two different query
mechanisms.

The first restarts the VMs using the query used to wait on their asynchronous creation.
```bash
az vm restart --ids $(az vm list --query "join(' ', ${GROUP_QUERY}] | [].id)" \
    -o tsv) $1>/dev/null
```

The second uses a generic resource listing and query to fetch their IDs by tag.
```bash
az vm restart --ids $(az resource list --tag ${TAG} \
    --query "[?type=='Microsoft.Compute/virtualMachines'].id" -o tsv) $1>/dev/null
```

## To run this sample
`./restart-by-tag`

## Expected Output
```
Creating resource group GROUP1 in westus
Deploying vm named GROUP1-vm in GROUP1 with no waiting
Creating resource group GROUP2 in westus
Deploying vm named GROUP2-vm in GROUP2 with no waiting
Creating resource group GROUP3 in westus
Deploying vm named GROUP3-vm in GROUP3 with no waiting
Waiting for the vms to complete provisioning

Still not provisioned. Sleeping for 20 seconds.
Still not provisioned. Sleeping for 20 seconds.
Still not provisioned. Sleeping for 20 seconds.
Still not provisioned. Sleeping for 20 seconds.
Still not provisioned. Sleeping for 20 seconds.
Still not provisioned. Sleeping for 20 seconds.

Restarting virtual machines with ids via the group query

Restarting virtual machines with a given tag

To delete the created resource groups run the following.
az group delete -n GROUP1 --no-wait --force && \
az group delete -n GROUP2 --no-wait --force && \
az group delete -n GROUP3 --no-wait --force
```

## To tear down this sample
```bash
az group delete -n GROUP1 --no-wait --force && \ 
az group delete -n GROUP2 --no-wait --force && \
az group delete -n GROUP3 --no-wait --force
```