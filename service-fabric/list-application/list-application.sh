#!/bin/bash

# Select cluster
sfctl cluster select \
    --endpoint http://svcfab1.westus2.cloudapp.azure.com:19080

# Retrieve all applications from the cluster
sfctl application list