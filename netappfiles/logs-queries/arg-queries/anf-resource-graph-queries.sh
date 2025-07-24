#!/bin/bash
# Azure Resource Graph (ARG) Queries for Azure NetApp Files
# These queries help you analyze ANF resources and configurations across subscriptions

echo "🔍 Azure NetApp Files - Resource Graph Queries"
echo "=============================================="

# Function to run ARG query with az graph
run_arg_query() {
    local query_name="$1"
    local query="$2"
    
    echo ""
    echo "📊 $query_name"
    echo "$(printf '=%.0s' {1..50})"
    echo "Query:"
    echo "$query"
    echo ""
    echo "Results:"
    
    az graph query -q "$query" --output table
}

# Query 1: All NetApp Files accounts
query1="Resources
| where type == 'microsoft.netapp/netappaccounts'
| project name, resourceGroup, location, subscriptionId
| order by name asc"

run_arg_query "All NetApp Files Accounts" "$query1"

# Query 2: NetApp Files volumes with size and service level
query2="Resources
| where type == 'microsoft.netapp/netappaccounts/capacitypools/volumes'
| extend volumeProps = properties
| project 
    name,
    resourceGroup,
    location,
    serviceLevel = volumeProps.serviceLevel,
    sizeGB = volumeProps.usageThreshold / 1073741824,
    provisioningState = volumeProps.provisioningState,
    creationToken = volumeProps.creationToken
| order by sizeGB desc"

run_arg_query "NetApp Files Volumes with Size and Service Level" "$query2"

# Query 3: Find volumes by service level
echo ""
echo "🏎️  Find volumes by service level (Ultra, Premium, Standard):"
read -p "Enter service level (Ultra/Premium/Standard): " service_level

query3="Resources
| where type == 'microsoft.netapp/netappaccounts/capacitypools/volumes'
| extend volumeProps = properties
| where volumeProps.serviceLevel == '$service_level'
| project 
    name,
    resourceGroup,
    location,
    sizeGB = volumeProps.usageThreshold / 1073741824,
    provisioningState = volumeProps.provisioningState
| order by sizeGB desc"

run_arg_query "Volumes with $service_level Service Level" "$query3"

# Query 4: NetApp Files capacity pools utilization
query4="Resources
| where type == 'microsoft.netapp/netappaccounts/capacitypools'
| extend poolProps = properties
| project 
    name,
    resourceGroup,
    location,
    serviceLevel = poolProps.serviceLevel,
    sizeTB = poolProps.size / 1099511627776,
    provisioningState = poolProps.provisioningState
| order by sizeTB desc"

run_arg_query "Capacity Pools and Their Sizes" "$query4"

# Query 5: ANF resources by location
query5="Resources
| where type startswith 'microsoft.netapp/'
| summarize count() by location, type
| order by location, type"

run_arg_query "ANF Resources by Location and Type" "$query5"

# Query 6: Find cross-region replication relationships
query6="Resources
| where type == 'microsoft.netapp/netappaccounts/capacitypools/volumes'
| extend volumeProps = properties
| where isnotnull(volumeProps.dataProtection)
| project 
    name,
    resourceGroup,
    location,
    replicationSchedule = volumeProps.dataProtection.replication.replicationSchedule,
    remoteVolumeRegion = volumeProps.dataProtection.replication.remoteVolumeRegion
| order by name"

run_arg_query "Cross-Region Replication Volumes" "$query6"

# Query 7: Volumes with snapshots enabled
query7="Resources
| where type == 'microsoft.netapp/netappaccounts/capacitypools/volumes'
| extend volumeProps = properties
| where isnotnull(volumeProps.dataProtection.snapshot)
| project 
    name,
    resourceGroup,
    location,
    snapshotPolicyId = volumeProps.dataProtection.snapshot.snapshotPolicyId
| order by name"

run_arg_query "Volumes with Snapshot Policies" "$query7"

# Query 8: ANF resources with specific tags
echo ""
echo "🏷️  Find ANF resources with specific tags:"
read -p "Enter tag name: " tag_name
read -p "Enter tag value: " tag_value

query8="Resources
| where type startswith 'microsoft.netapp/'
| where tags['$tag_name'] == '$tag_value'
| project name, resourceGroup, location, type, tags
| order by name"

run_arg_query "ANF Resources with Tag $tag_name=$tag_value" "$query8"

# Query 9: Large volumes (>= 1TB)
query9="Resources
| where type == 'microsoft.netapp/netappaccounts/capacitypools/volumes'
| extend volumeProps = properties
| extend sizeTB = volumeProps.usageThreshold / 1099511627776
| where sizeTB >= 1
| project 
    name,
    resourceGroup,
    location,
    sizeTB,
    serviceLevel = volumeProps.serviceLevel,
    provisioningState = volumeProps.provisioningState
| order by sizeTB desc"

run_arg_query "Large Volumes (>= 1TB)" "$query9"

# Query 10: ANF resources created in the last 30 days
query10="Resources
| where type startswith 'microsoft.netapp/'
| where todatetime(properties.creationTime) >= ago(30d)
| project 
    name,
    resourceGroup,
    location,
    type,
    createdDate = todatetime(properties.creationTime)
| order by createdDate desc"

run_arg_query "ANF Resources Created in Last 30 Days" "$query10"

echo ""
echo "💡 Additional useful queries you can run:"
echo ""
echo "1. Export results to CSV:"
echo "   az graph query -q \"<query>\" --output table > anf-resources.csv"
echo ""
echo "2. Query specific subscriptions:"
echo "   az graph query -q \"<query>\" --subscriptions sub1 sub2"
echo ""
echo "3. Query across management groups:"
echo "   az graph query -q \"<query>\" --management-groups mg1 mg2"
echo ""
echo "4. Complex filtering example:"
echo "   Resources | where type == 'microsoft.netapp/netappaccounts/capacitypools/volumes'"
echo "   | extend props = properties"
echo "   | where props.serviceLevel == 'Ultra' and props.usageThreshold > 1099511627776"
echo ""
echo "✅ Resource Graph queries completed!"
echo "For more advanced queries, see: https://docs.microsoft.com/azure/governance/resource-graph/"
