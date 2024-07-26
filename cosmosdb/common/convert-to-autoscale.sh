#!/bin/bash

# Passed validation in Cloud Shell on 7/25/2024

# <FullScript>
# Azure Cosmos DB users can migrate from standard provisioned to autoscale
# throughput and back again. Most users can benefit from autoscale throughput
# to save on costs and avoid over-provisioning. This script migrates all
# provisioned throughput to autoscale throughput for all Cosmos DB accounts
# in the current subscription for NoSQL, MongoDB, Cassandra, Gremlin, and Table
# database and container level resources in the accounts.


# These can remain commented out if running in Azure Cloud Shell
#az login
#az account set -s {your subscription id}

throughtput=0

# Get the list of resource groups in the current subscription
resourceGroups=$(az group list --query "[].name" -o tsv)

# Loop through every resource group in the subscription
for resourceGroup in $resourceGroups; do
    echo "Processing resource group: $resourceGroup"

    # Get the list of Cosmos DB accounts in this resource group
    accounts=$(az cosmosdb list -g $resourceGroup --query "[].name" -o tsv)

    # Loop through every Cosmos DB account in the resource group
    for account in $accounts; do

        echo "Processing account: $account"

        # Get the list of SQL databases in this account
        databases=$(az cosmosdb sql database list -g $resourceGroup -a $account --query "[].name" -o tsv)

        # Loop through SQL databases in the account
        for database in $databases; do
            throughput=$(az cosmosdb sql database throughput show -g $resourceGroup -a $account -n $database --query resource.throughput -o tsv)
            if [ $throughput -gt 0 ]; then
                echo "$database has throughput, attempting to migrate to autoscale"
                # Migrate the database to autoscale throughput
                az cosmosdb sql database throughput migrate -g $resourceGroup -a $account -n $database -t "autoscale"
                if [ $? -eq 0 ]; then
                    echo "Successfully migrated throughput for database: $database in Cosmos DB account $account"
                fi
            else
                echo "$database does not have throughput"
            fi

            # Loop through SQL containers in the database
            containers=$(az cosmosdb sql container list -g $resourceGroup -a $account -d $database --query "[].name" -o tsv)

            for container in $containers; do
                throughput=$(az cosmosdb sql container throughput show -g $resourceGroup -a $account -d $database -n $container --query resource.throughput -o tsv)
                if [ $throughput -gt 0 ]; then
                    echo "$container has throughput, attempting to migrate to autoscale"
                    # Migrate the container to autoscale throughput
                    az cosmosdb sql container throughput migrate -g $resourceGroup -a $account -d $database -n $container -t "autoscale"
                    if [ $? -eq 0 ]; then
                        echo "Successfully migrated throughput for container: $container in Cosmos DB account $account and database $database"
                    fi
                else
                    echo "$container does not have throughput"
                fi
            done
        done

        # Get the list of MongoDB databases in this account
        databases=$(az cosmosdb mongodb database list -g $resourceGroup -a $account --query "[].name" -o tsv)

        # Loop through MongoDB databases in the account
        for database in $databases; do
            throughput=$(az cosmosdb mongodb database throughput show -g $resourceGroup -a $account -n $database --query resource.throughput -o tsv)
            if [ $throughput -gt 0 ]; then
                echo "$database has throughput, attempting to migrate to autoscale"
                # Migrate the database to autoscale throughput
                az cosmosdb mongodb database throughput migrate -g $resourceGroup -a $account -n $database -t "autoscale"
                if [ $? -eq 0 ]; then
                    echo "Successfully migrated throughput for database: $database in Cosmos DB account $account"
                fi
            else
                echo "$database does not have throughput"
            fi

            # Loop through MongoDB collections in the database
            collections=$(az cosmosdb mongodb collection list -g $resourceGroup -a $account -d $database --query "[].name" -o tsv)

            for collection in $collections; do
                throughput=$(az cosmosdb mongodb collection throughput show -g $resourceGroup -a $account -d $database -n $collection --query resource.throughput -o tsv)
                if [ $throughput -gt 0 ]; then
                    echo "$collection has throughput, attempting to migrate to autoscale"
                    # Migrate the collection to autoscale throughput
                    az cosmosdb mongodb collection throughput migrate -g $resourceGroup -a $account -d $database -n $collection -t "autoscale"
                    if [ $? -eq 0 ]; then
                        echo "Successfully migrated throughput for collection: $collection in Cosmos DB account $account and database $database"
                    fi
                else
                    echo "$collection does not have throughput"
                fi
            done
        done

        # Get the list of Cassandra keyspaces in this account
        keyspaces=$(az cosmosdb cassandra keyspace list -g $resourceGroup -a $account --query "[].name" -o tsv)

        # Loop through Cassandra keyspaces in the account
        for keyspace in $keyspaces; do
            throughput=$(az cosmosdb cassandra keyspace throughput show -g $resourceGroup -a $account -n $keyspace --query resource.throughput -o tsv)
            if [ $throughput -gt 0 ]; then
                echo "$keyspace has throughput, attempting to migrate to autoscale"
                # Migrate the keyspace to autoscale throughput
                az cosmosdb cassandra keyspace throughput migrate -g $resourceGroup -a $account -n $keyspace -t "autoscale"
                if [ $? -eq 0 ]; then
                    echo "Successfully migrated throughput for keyspace: $keyspace in Cosmos DB account $account"
                fi
            else
                echo "$keyspace does not have throughput"
            fi

            # Loop through Cassandra tables in the keyspace
            tables=$(az cosmosdb cassandra table list -g $resourceGroup -a $account -k $keyspace --query "[].name" -o tsv)

            for table in $tables; do
                throughput=$(az cosmosdb cassandra table throughput show -g $resourceGroup -a $account -k $keyspace -n $table --query resource.throughput -o tsv)
                if [ $throughput -gt 0 ]; then
                    echo "$table has throughput, attempting to migrate to autoscale"
                    # Migrate the table to autoscale throughput
                    az cosmosdb cassandra table throughput migrate -g $resourceGroup -a $account -k $keyspace -n $table -t "autoscale"
                    if [ $? -eq 0 ]; then
                        echo "Successfully migrated throughput for table: $table in Cosmos DB account $account and keyspace $keyspace"
                    fi
                else
                    echo "$table does not have throughput"
                fi
            done
        done

        # Get the list of Gremlin databases in this account
        databases=$(az cosmosdb gremlin database list -g $resourceGroup -a $account --query "[].name" -o tsv)

        # Loop through Gremlin databases in the account
        for database in $databases; do
            throughput=$(az cosmosdb gremlin database throughput show -g $resourceGroup -a $account -n $database --query resource.throughput -o tsv)
            if [ $throughput -gt 0 ]; then
                echo "$database has throughput, attempting to migrate to autoscale"
                # Migrate the database to autoscale throughput
                az cosmosdb gremlin database throughput migrate -g $resourceGroup -a $account -n $database -t "autoscale"
                if [ $? -eq 0 ]; then
                    echo "Successfully migrated throughput for database: $database in Cosmos DB account $account"
                fi
            else
                echo "$database does not have throughput"
            fi

            # Loop through Gremlin graphs in the database
            graphs=$(az cosmosdb gremlin graph list -g $resourceGroup -a $account -d $database --query "[].name" -o tsv)

            for graph in $graphs; do
                throughput=$(az cosmosdb gremlin graph throughput show -g $resourceGroup -a $account -d $database -n $graph --query resource.throughput -o tsv)
                if [ $throughput -gt 0 ]; then
                    echo "$graph has throughput, attempting to migrate to autoscale"
                    # Migrate the graph to autoscale throughput
                    az cosmosdb gremlin graph throughput migrate -g $resourceGroup -a $account -d $database -n $graph -t "autoscale"
                    if [ $? -eq 0 ]; then
                        echo "Successfully migrated throughput for graph: $graph in Cosmos DB account $account and database $database"
                    fi
                else
                    echo "$graph does not have throughput"
                fi
            done
        done

        # Get the list of Table databases in this account
        tables=$(az cosmosdb table list -g $resourceGroup -a $account --query "[].name" -o tsv)

        # Loop through Table databases in the account
        for table in $tables; do
            throughput=$(az cosmosdb table throughput show -g $resourceGroup -a $account -n $table --query resource.throughput -o tsv)
            if [ $throughput -gt 0 ]; then
                echo "$table has throughput, attempting to migrate to autoscale"
                # Migrate the table to autoscale throughput
                az cosmosdb table throughput migrate -g $resourceGroup -a $account -n $table -t "autoscale"
                if [ $? -eq 0 ]; then
                    echo "Successfully migrated throughput for table: $table in Cosmos DB account $account"
                fi
            else
                echo "$table does not have throughput"
            fi
        done
    done
done

echo "All Done! Enjoy your new autoscale throughput Cosmos DB accounts!"
