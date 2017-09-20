#!/bin/bash

# Select cluster
sfctl cluster select \
    --endpoint http://svcfab1.westus2.cloudapp.azure.com:19080

# Upload the latest bits of an application
sfctl application upload --path ~/app_package_dir_2

# Provision the new application
sfctl application provision --application-type-build-path app_package_dir_2

# Upgrade an existing up with the new version
sfctl application upgrade --app-id TestApp --app-version 2.0.0 --parameters "{\"test\":\"value\"}" --mode Monitored