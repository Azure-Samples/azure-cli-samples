NAME="AllowNfsFileShares"
## Use a persistent volume with Azure Files

## Dynamically create Azure Files PVs by using the built-in storage classes

## Create a custom storage class

## Resize a persistent volume

## NFS file shares

az feature register --namespace "Microsoft.Storage" --name $NAME
az feature list -o table --query "[?contains(name, 'Microsoft.Storage/AllowNfsFileShares')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.Storage
## Windows containers

## Next steps
