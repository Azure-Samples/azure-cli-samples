# Azure Front Door: Deploy custom domain

Deploy a Custom Domain name and TLS certificate on an Azure Front Door front-end.

> ℹ As of April 2021, Front Door managed TLS certificates are not yet supported on Azure Front Door. Support is coming soon. Until then you must bring your own certificate for Apex domains on Front Door, which requires some manual steps.

Two scripts provided for this sample:

* [deploy-custom-domain.sh](deploy-custom-domain.sh) - fully automated provisioning of TLS cert on subdomain
* deploy-apex-domain.sh (TODO) - manual steps required for CSR in Azure Key Vault

Scripted process:

1. Create a resource group
1. Create a storage account to host a SPA
1. Enable SPA hosting on storage account



## Links and references

* [Deploying a static site using AZ CLI] - Dave Paquette

<!-- link refs -->
[Deploying a static site using AZ CLI]: https://www.davepaquette.com/archive/2020/05/10/deploying-a-static-site-to-azure-using-the-az-cli.aspx