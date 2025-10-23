#!/bin/bash
# Azure NetApp Files Cost Analysis and Billing Management
# Comprehensive cost tracking, analysis, and optimization recommendations

set -e

# Configuration
SCRIPT_NAME="ANF Cost Analysis"
LOG_FILE="anf-cost-analysis-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to check Azure CLI login
check_azure_login() {
    if ! az account show &>/dev/null; then
        error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    log "Azure CLI authentication verified"
}

# Function to get current subscription info
get_subscription_info() {
    local subscription_id=$(az account show --query id -o tsv)
    local subscription_name=$(az account show --query name -o tsv)
    log "Current subscription: $subscription_name ($subscription_id)"
    echo "$subscription_id"
}

# Function to analyze ANF costs for specific time period
analyze_anf_costs() {
    local start_date="$1"
    local end_date="$2"
    local subscription_id="$3"
    
    log "Analyzing ANF costs from $start_date to $end_date"
    
    # Get consumption data for NetApp Files
    info "Fetching consumption data for Azure NetApp Files..."
    az consumption usage list \
        --start-date "$start_date" \
        --end-date "$end_date" \
        --query "[?contains(instanceName, 'netapp') || contains(meterCategory, 'Storage')].{Date:usageStart,Service:meterCategory,SubCategory:meterSubCategory,Resource:instanceName,Location:instanceLocation,Quantity:quantity,Unit:unit,Cost:pretaxCost,Currency:currency}" \
        --output table
    
    # Get total ANF costs
    local total_cost=$(az consumption usage list \
        --start-date "$start_date" \
        --end-date "$end_date" \
        --query "[?contains(instanceName, 'netapp') || contains(meterCategory, 'Storage')].pretaxCost" \
        --output tsv | awk '{sum += $1} END {print sum}')
    
    if [ ! -z "$total_cost" ]; then
        log "Total ANF costs for period: $total_cost"
    else
        warn "No ANF costs found for the specified period"
    fi
}

# Function to get current ANF resource costs
get_current_anf_resources() {
    log "Analyzing current ANF resources and estimated costs..."
    
    # Get all NetApp accounts
    info "NetApp Accounts:"
    az netappfiles account list --query "[].{Name:name,ResourceGroup:resourceGroup,Location:location,ProvisioningState:provisioningState}" --output table
    
    # Get all capacity pools with size and service level
    info "Capacity Pools:"
    az netappfiles pool list --query "[].{Account:accountName,Pool:name,Size:size,ServiceLevel:serviceLevel,UtilizedSize:utilizedSize,ProvisioningState:provisioningState}" --output table
    
    # Calculate total provisioned capacity
    local total_capacity=$(az netappfiles pool list --query "[].size" --output tsv | awk '{sum += $1} END {print sum/1024/1024/1024/1024}')
    if [ ! -z "$total_capacity" ]; then
        log "Total provisioned capacity: ${total_capacity} TiB"
    fi
    
    # Get all volumes with usage details
    info "Volumes:"
    az netappfiles volume list --query "[].{Account:accountName,Pool:poolName,Volume:name,Size:usageThreshold,Used:actualThroughputMibps,ServiceLevel:serviceLevel,Protocol:protocolTypes,State:provisioningState}" --output table
}

# Function to generate cost optimization recommendations
generate_cost_recommendations() {
    log "Generating cost optimization recommendations..."
    
    echo -e "\n${BLUE}=== ANF COST OPTIMIZATION RECOMMENDATIONS ===${NC}"
    
    # Check for unused volumes
    info "Checking for potentially unused volumes..."
    az netappfiles volume list --query "[?throughputMibps == null || throughputMibps < \`1\`].{Account:accountName,Pool:poolName,Volume:name,Size:usageThreshold,ServiceLevel:serviceLevel}" --output table
    
    # Check for over-provisioned pools
    info "Checking for over-provisioned capacity pools..."
    az netappfiles pool list --query "[?utilizedSize < size * 0.5].{Account:accountName,Pool:name,Size:size,Utilized:utilizedSize,Efficiency:round(utilizedSize/size*100)}" --output table
    
    echo -e "\n${YELLOW}Cost Optimization Tips:${NC}"
    echo "1. Consider using Standard service level for non-critical workloads"
    echo "2. Right-size capacity pools based on actual utilization"
    echo "3. Use volume quotas to prevent over-consumption"
    echo "4. Monitor and delete unused snapshots"
    echo "5. Consider cross-region replication only when necessary"
    echo "6. Use Azure Advisor recommendations for ANF"
}

# Function to export cost data to CSV
export_cost_data() {
    local start_date="$1"
    local end_date="$2"
    local output_file="anf-costs-$(date +%Y%m%d).csv"
    
    log "Exporting cost data to $output_file"
    
    az consumption usage list \
        --start-date "$start_date" \
        --end-date "$end_date" \
        --query "[?contains(instanceName, 'netapp') || contains(meterCategory, 'Storage')]" \
        --output json > "$output_file.json"
    
    # Convert to CSV format
    jq -r '["Date","Service","SubCategory","Resource","Location","Quantity","Unit","Cost","Currency"] as $header | $header, (.[] | [.usageStart,.meterCategory,.meterSubCategory,.instanceName,.instanceLocation,.quantity,.unit,.pretaxCost,.currency]) | @csv' "$output_file.json" > "$output_file"
    
    log "Cost data exported to $output_file"
    rm "$output_file.json"
}

# Function to set up cost alerts
setup_cost_alerts() {
    local budget_amount="$1"
    local resource_group="$2"
    
    if [ -z "$budget_amount" ] || [ -z "$resource_group" ]; then
        error "Budget amount and resource group required for cost alerts"
        return 1
    fi
    
    log "Setting up cost alerts for resource group: $resource_group"
    
    # Create budget for ANF resources
    local budget_name="anf-budget-$(date +%Y%m)"
    
    az consumption budget create \
        --budget-name "$budget_name" \
        --amount "$budget_amount" \
        --resource-group "$resource_group" \
        --time-grain "Monthly" \
        --start-date "$(date +%Y-%m-01)" \
        --end-date "$(date -d '+1 year' +%Y-%m-01)" \
        --notifications '[{"enabled":true,"operator":"GreaterThan","threshold":80,"contactEmails":["admin@company.com"],"thresholdType":"Actual"}]'
    
    log "Cost alert budget created: $budget_name"
}

# Function to get ANF pricing information
get_anf_pricing() {
    log "Getting current ANF pricing information..."
    
    echo -e "\n${BLUE}=== ANF PRICING REFERENCE ===${NC}"
    echo "Note: Prices vary by region and are subject to change"
    echo ""
    echo "Service Levels (per TiB/month in East US):"
    echo "- Standard: ~\$0.000202/GiB/hour (~\$146/TiB/month)"
    echo "- Premium: ~\$0.000403/GiB/hour (~\$293/TiB/month)"
    echo "- Ultra: ~\$0.000538/GiB/hour (~\$391/TiB/month)"
    echo ""
    echo "Additional costs:"
    echo "- Snapshots: ~\$0.05/GiB/month"
    echo "- Cross-region replication: ~\$0.10/GiB/month"
    echo "- Cross-zone replication: ~\$0.05/GiB/month"
    echo ""
    echo "For current pricing, visit: https://azure.microsoft.com/pricing/details/netapp/"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -s, --start-date DATE     Start date for cost analysis (YYYY-MM-DD)"
    echo "  -e, --end-date DATE       End date for cost analysis (YYYY-MM-DD)"
    echo "  -r, --resource-group RG   Resource group for cost alerts"
    echo "  -b, --budget AMOUNT       Budget amount for cost alerts"
    echo "  -x, --export             Export cost data to CSV"
    echo "  -p, --pricing            Show ANF pricing information"
    echo "  -c, --current            Analyze current resources only"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -s 2025-01-01 -e 2025-01-31    # Analyze costs for January"
    echo "  $0 -c                              # Analyze current resources"
    echo "  $0 -x -s 2025-01-01 -e 2025-01-31 # Export cost data"
    echo "  $0 -r myRG -b 1000                 # Set up \$1000 budget alert"
}

# Main function
main() {
    log "Starting $SCRIPT_NAME"
    
    # Default values
    START_DATE=""
    END_DATE=""
    RESOURCE_GROUP=""
    BUDGET_AMOUNT=""
    EXPORT_DATA=false
    SHOW_PRICING=false
    CURRENT_ONLY=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--start-date)
                START_DATE="$2"
                shift 2
                ;;
            -e|--end-date)
                END_DATE="$2"
                shift 2
                ;;
            -r|--resource-group)
                RESOURCE_GROUP="$2"
                shift 2
                ;;
            -b|--budget)
                BUDGET_AMOUNT="$2"
                shift 2
                ;;
            -x|--export)
                EXPORT_DATA=true
                shift
                ;;
            -p|--pricing)
                SHOW_PRICING=true
                shift
                ;;
            -c|--current)
                CURRENT_ONLY=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    check_azure_login
    subscription_id=$(get_subscription_info)
    
    if [ "$SHOW_PRICING" = true ]; then
        get_anf_pricing
    fi
    
    if [ "$CURRENT_ONLY" = true ]; then
        get_current_anf_resources
        generate_cost_recommendations
    elif [ ! -z "$START_DATE" ] && [ ! -z "$END_DATE" ]; then
        analyze_anf_costs "$START_DATE" "$END_DATE" "$subscription_id"
        
        if [ "$EXPORT_DATA" = true ]; then
            export_cost_data "$START_DATE" "$END_DATE"
        fi
    fi
    
    if [ ! -z "$RESOURCE_GROUP" ] && [ ! -z "$BUDGET_AMOUNT" ]; then
        setup_cost_alerts "$BUDGET_AMOUNT" "$RESOURCE_GROUP"
    fi
    
    if [ -z "$START_DATE" ] && [ -z "$END_DATE" ] && [ "$CURRENT_ONLY" != true ] && [ "$SHOW_PRICING" != true ]; then
        warn "No analysis parameters specified. Use -h for help."
        get_current_anf_resources
        generate_cost_recommendations
    fi
    
    log "$SCRIPT_NAME completed successfully"
}

# Run main function with all arguments
main "$@"
