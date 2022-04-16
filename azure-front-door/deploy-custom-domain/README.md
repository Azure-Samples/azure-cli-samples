# Azure Front Door: Deploy custom domain

Deploy a Custom Domain name and TLS certificate on an Azure Front Door front-end.

Script provided for this sample:

* [deploy-custom-domain.sh](deploy-custom-domain.sh)

## Deploy custom domain name

Fully automated provisioning of Azure Front Door with custom domain name (hosted by Azure DNS) and TLS cert.

### Pre-requisites

1. [Host your domain in Azure DNS] and create a public zone.

### Getting started

To deploy this sample, review and change hardcoded variables if required. Then execute:

```bash
AZURE_DNS_ZONE_NAME=www.contoso.com AZURE_DNS_ZONE_RESOURCE_GROUP=contoso-rg ./deploy-custom-apex-domain.sh
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
1. Enable HTTPS with Front Door managed cert


<!-- link refs -->
[Deploying a static site using AZ CLI]: https://www.davepaquette.com/archive/2020/05/10/deploying-a-static-site-to-azure-using-the-az-cli.aspx
[Add certificates in Key Vault]:https://docs.microsoft.com/en-us/azure/key-vault/certificates/create-certificate-signing-request?tabs=azure-portal#add-certificates-in-key-vault-issued-by-non-partnered-cas
[Host your domain in Azure DNS]:https://docs.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns
