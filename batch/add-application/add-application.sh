#!/bin/bash

# Authenticate CLI session.
az login

# Create a new application.
az batch application create \
    --resource-group myresourcegroup \
    --name mybatchaccount \
    --application-id myapp \
    --display-name "My Application"

# An application can reference multiple application executable packages
# of different versions. The executables and any dependencies will need
# to be zipped up for the package. Once uploaded, the CLI will attempt
# to activate the package so that it's ready for use.
az batch application package create \
    --resource-group myresourcegroup \
    --name mybatchaccount \
    --application-id myapp \
    --package-file my-application-exe.zip \
    --version 1.0

# We will update our application to assign the newly added application
# package as the default version.
az batch application set \
    --resource-group myresourcegroup \
    --name mybatchaccount \
    --application-id myapp \
    --default-version 1.0