#!/bin/bash

# Authenticate CLI session.
az login

# Select cluster
az sf cluster select \
    --endpoint http://svcfab1.westus2.cloudapp.azure.com:19080

# Upload the application files to the image store
# (note the last folder name, Debug in this example)
az sf application upload \
    --path  C:\Code\svcfab-vs\svcfab-vs\pkg\Debug \
    --show-progress

# Register the application (manifest files) from the image store
# (Note the last folder from the previous command is used: Debug)
az sf application provision \
    --application-type-build-path Debug \
    --timeout 500

# Create an instance of the registered application and 
# auto deploy any defined services
az sf application create \
    --app-name fabric:/MyApp \
    --app-type MyAppType \
    --app-version 1.0.0
    