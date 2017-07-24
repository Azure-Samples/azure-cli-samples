#!/bin/bash

# Authenticate CLI session.
az login

# Select cluster
az sf cluster select \
    --endpoint http://svcfab1.westus2.cloudapp.azure.com:19080

# Delete the application
az sf application delete \
    --application-id svcfab_app \
    --timeout 500

# Unprovision the application type
az sf application unprovision \
    --application-type-name svcfab_appType \
    --application-type-version 1.0.0 \
    --timeout 500

# Delete the application files from the image store
az sf application package-delete \
    --content-path myappfolder