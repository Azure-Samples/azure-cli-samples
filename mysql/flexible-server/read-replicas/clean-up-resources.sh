#!/bin/bash

RESOURCE_GROUP="myresourcegroup"
SOURCE_SERVER="mydemoserver" # Enter source server name.
REPLICA_NAME="mydemoserver-replica" # Enter replica server name. 

#Delete Source Server and Replicas
az mysql flexible-server delete \
--resource-group $RESOURCE_GROUP 
--name $SOURCE_SERVER

az mysql flexible-server delete \
--resource-group $RESOURCE_GROUP 
--name $REPLICA_NAME
