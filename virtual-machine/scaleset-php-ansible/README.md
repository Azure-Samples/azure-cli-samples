# PHP app tier provisioned with Ansible

Create an Azure Scale Set with Azure CLI 2.0 using a custom script extension to bootstrap 
virtual machine instances running CentOS. The custom script extension installs the prerequisites 
for Ansible, and then installs an extremely simple PHP app running on Apache.

## To run
`./build-stack`

## To teardown
`az group delete -n php-stack`
