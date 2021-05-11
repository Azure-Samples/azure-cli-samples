# Azure Front Door: Deploy custom domain

Deploy a Custom Domain name and TLS certificate on an Azure Front Door front-end.

Two scripts provided for this sample:

* [deploy-custom-domain.sh](deploy-custom-domain.sh)
* [deploy-custom-apex-domain.sh](deploy-custom-apex-domain.sh)

## Deploy custom domain name

Fully automated provisioning of TLS cert on subdomain. Any DNS service can be used so Azure DNS is not used in this sample. 

### Pre-requisites

Two CNAME's must be created before running the script. In this example the Front Door profile name is `contoso` and the custom subdomain is `www.contoso.com`

```
www.contoso.com         CNAME   contoso.azurefd.net
afdverify.contoso.com   CNAME   afdverify.contoso.azurefd.net
```

### Getting started

To deploy this sample, review and change hardcoded variables if required. Then execute:

```bash
./deploy-custom-domain.sh
```

The script will:

1. Create a resource group
1. Create a storage account to host a SPA
1. Enable SPA hosting on storage account
1. Upload a "Hello world!" `index.html` file
1. Create a Front Door profile
1. Create a Front Door front-end endpoint for the custom domain
1. Add route from custom domain frontend to SPA origin
1. Add a routing rule to redirect HTTP -> HTTPS
1. Enable HTTPS with a Front Door managed TLS cert

## Deploy custom apex domain name

> ℹ As of April 2021, Front Door managed TLS certificates are not yet supported on Azure Front Door. Support is coming soon. 

Until Azure Front Door adds support for managed Apex domains, you must bring your own TLS certificate for Apex domains. You must also use Azure DNS as the DNS Service for the entire domain. This script uses Azure DNS and requires manual steps for the Certificate Signing Request (CSR).

### Pre-requisites

1. [Host your domain in Azure DNS] and create a public zone
1. Complete the CSR process in Azure Key Vault. See: [Add certificates in Key Vault].

### Getting started

To deploy this sample, review and change hardcoded variables if required. Then execute:

```bash
./deploy-custom-apex-domain.sh
```

The script will:

1. Create a resource group
1. Create a storage account to host a SPA
1. Enable SPA hosting on storage account
1. Upload a "Hello world!" `index.html` file
1. Create a Front Door profile
1. Create a DNS alias for the Apex that resolves to the Front Door
1. Create a CNAME for the `adverify` hostname
1. Create a Front Door front-end endpoint for the custom domain
1. Add route from custom domain frontend to SPA origin
1. Add a routing rule to redirect HTTP -> HTTPS
1. Enable HTTPS with a Key Vault managed TLS cert


## Links and references

* [Deploying a static site using AZ CLI] - Dave Paquette

<!-- link refs -->
[Deploying a static site using AZ CLI]: https://www.davepaquette.com/archive/2020/05/10/deploying-a-static-site-to-azure-using-the-az-cli.aspx
[Add certificates in Key Vault]:https://docs.microsoft.com/en-us/azure/key-vault/certificates/create-certificate-signing-request?tabs=azure-portal#add-certificates-in-key-vault-issued-by-non-partnered-cas
[Host your domain in Azure DNS]:https://docs.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns