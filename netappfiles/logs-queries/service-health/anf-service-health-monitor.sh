#!/bin/bash
# Azure NetApp Files - Service Health Monitor
# Monitors Azure Service Health for NetApp Files service issues

set -euo pipefail

# Script configuration
SCRIPT_NAME="anf-service-health-monitor"
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="$(date +%Y-%m-%d)"

# Default values
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
REGION="eastus"
TIME_RANGE="24h"
OUTPUT_FORMAT="table"
ALERT_WEBHOOK=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_alert() {
    echo -e "${PURPLE}[ALERT]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Azure NetApp Files - Service Health Monitor

Monitors Azure Service Health for NetApp Files related incidents and advisories.

Usage: $0 [OPTIONS]

OPTIONS:
    -s, --subscription      Subscription ID (optional, uses default if not specified)
    -g, --resource-group    Resource group to monitor (optional)
    -r, --region           Azure region to monitor (default: eastus)
    -t, --time-range       Time range for health events (1h, 24h, 7d, 30d) (default: 24h)
    -o, --output           Output format (table, json, tsv) (default: table)
    -w, --webhook          Webhook URL for alerts (optional)
    --active-only          Show only active service issues
    --include-planned      Include planned maintenance events
    -h, --help             Show this help message

Examples:
    $0                                          # Check service health with defaults
    $0 -r westus2 -t 7d                       # Check West US 2 for last 7 days
    $0 -s mySubId -g myRG --active-only       # Check specific subscription/RG for active issues
    $0 -o json --include-planned              # Get detailed JSON output with planned maintenance

Service Health Categories:
    • Service Issues: Unplanned outages affecting Azure NetApp Files
    • Planned Maintenance: Scheduled maintenance that may impact service
    • Health Advisories: Guidance on service configurations or usage
    • Security Advisories: Security-related guidance for the service

EOF
}

# Parse command line arguments
parse_arguments() {
    ACTIVE_ONLY=false
    INCLUDE_PLANNED=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--subscription)
                SUBSCRIPTION_ID="$2"
                shift 2
                ;;
            -g|--resource-group)
                RESOURCE_GROUP="$2"
                shift 2
                ;;
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -t|--time-range)
                TIME_RANGE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -w|--webhook)
                ALERT_WEBHOOK="$2"
                shift 2
                ;;
            --active-only)
                ACTIVE_ONLY=true
                shift
                ;;
            --include-planned)
                INCLUDE_PLANNED=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validation functions
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Validate time range format
    if [[ ! "$TIME_RANGE" =~ ^[0-9]+[hdw]$ ]]; then
        log_error "Invalid time range format. Use format like: 1h, 24h, 7d, 30d"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Convert time range to ISO format
convert_time_range() {
    local range="$1"
    local number="${range%[hdw]}"
    local unit="${range: -1}"
    
    case $unit in
        h)
            echo "PT${number}H"
            ;;
        d)
            echo "P${number}D"
            ;;
        w)
            echo "P$((number * 7))D"
            ;;
        *)
            echo "PT24H"  # Default to 24 hours
            ;;
    esac
}

# Get service health events
get_service_health_events() {
    log_info "Checking Azure Service Health for NetApp Files..."
    
    local start_time
    start_time=$(date -u -d "-${TIME_RANGE/[hdw]/} ${TIME_RANGE: -1}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Build base query
    local query_filter="eventType eq 'ServiceIssue' or eventType eq 'PlannedMaintenance'"
    
    if [[ "$ACTIVE_ONLY" == "true" ]]; then
        query_filter="$query_filter and status eq 'Active'"
    fi
    
    if [[ "$INCLUDE_PLANNED" == "false" ]]; then
        query_filter="eventType eq 'ServiceIssue'"
    fi
    
    # Add NetApp Files specific filter
    query_filter="$query_filter and (contains(title, 'NetApp') or contains(summary, 'NetApp') or contains(title, 'Storage'))"
    
    # Execute query
    local cmd="az rest --method GET --url 'https://management.azure.com"
    
    if [[ -n "$SUBSCRIPTION_ID" ]]; then
        cmd="$cmd/subscriptions/$SUBSCRIPTION_ID"
    else
        # Get default subscription
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        cmd="$cmd/subscriptions/$SUBSCRIPTION_ID"
    fi
    
    cmd="$cmd/providers/Microsoft.ResourceHealth/events'"
    cmd="$cmd --url-parameters 'api-version=2022-10-01'"
    cmd="$cmd --url-parameters '\$filter=$query_filter'"
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        cmd="$cmd --query 'value'"
    else
        cmd="$cmd --query 'value[].{Title:name,Status:properties.status,EventType:properties.eventType,ImpactStartTime:properties.impactStartTime,LastUpdateTime:properties.lastUpdateTime,Summary:properties.summary}'"
    fi
    
    cmd="$cmd -o $OUTPUT_FORMAT"
    
    log_info "Executing service health query..."
    
    # Execute the command
    local result
    if result=$(eval "$cmd" 2>/dev/null); then
        if [[ "$OUTPUT_FORMAT" == "table" ]]; then
            if [[ -z "$result" || "$result" == "[]" ]]; then
                log_success "✅ No active service issues found for Azure NetApp Files"
            else
                log_warning "⚠️  Service health events found:"
                echo "$result"
            fi
        else
            echo "$result"
        fi
    else
        log_error "Failed to retrieve service health information"
        return 1
    fi
    
    return 0
}

# Get resource health for specific resources
get_resource_health() {
    if [[ -z "$RESOURCE_GROUP" ]]; then
        log_info "No resource group specified, skipping resource-specific health check"
        return 0
    fi
    
    log_info "Checking resource health for NetApp Files resources in $RESOURCE_GROUP..."
    
    # Get all NetApp accounts in the resource group
    local netapp_accounts
    netapp_accounts=$(az netappfiles account list -g "$RESOURCE_GROUP" --query '[].{Name:name,Id:id}' -o json 2>/dev/null)
    
    if [[ "$netapp_accounts" == "[]" || -z "$netapp_accounts" ]]; then
        log_info "No NetApp Files accounts found in resource group $RESOURCE_GROUP"
        return 0
    fi
    
    log_info "Found NetApp Files accounts, checking resource health..."
    
    # Check health for each account
    echo "$netapp_accounts" | jq -r '.[] | .Id' | while read -r resource_id; do
        local resource_name
        resource_name=$(echo "$resource_id" | cut -d'/' -f9)
        
        log_info "Checking health for account: $resource_name"
        
        local health_status
        health_status=$(az rest --method GET \
            --url "https://management.azure.com${resource_id}/providers/Microsoft.ResourceHealth/availabilityStatuses/current" \
            --url-parameters "api-version=2022-10-01" \
            --query 'properties.availabilityState' -o tsv 2>/dev/null || echo "Unknown")
        
        case "$health_status" in
            "Available")
                log_success "✅ $resource_name: Healthy"
                ;;
            "Unavailable")
                log_error "❌ $resource_name: Unavailable"
                ;;
            "Degraded")
                log_warning "⚠️  $resource_name: Degraded"
                ;;
            *)
                log_info "ℹ️  $resource_name: Status unknown"
                ;;
        esac
    done
}

# Send alert to webhook if configured
send_alert() {
    local message="$1"
    
    if [[ -n "$ALERT_WEBHOOK" ]]; then
        log_info "Sending alert to webhook..."
        
        local payload
        payload=$(jq -n \
            --arg text "$message" \
            --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '{
                "text": $text,
                "timestamp": $timestamp,
                "service": "Azure NetApp Files",
                "source": "Service Health Monitor"
            }')
        
        if curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$ALERT_WEBHOOK" >/dev/null; then
            log_success "Alert sent successfully"
        else
            log_warning "Failed to send alert to webhook"
        fi
    fi
}

# Generate summary report
generate_summary() {
    log_info "Generating service health summary..."
    
    echo ""
    echo "🏥 Azure NetApp Files Service Health Summary"
    echo "============================================="
    echo "📅 Check Date: $(date)"
    echo "⏰ Time Range: $TIME_RANGE"
    echo "🌍 Region: $REGION"
    echo "📧 Subscription: ${SUBSCRIPTION_ID:-Default}"
    echo ""
    
    # Get current service status
    log_info "Current service status overview:"
    
    # Check if there are any active incidents
    local active_incidents
    active_incidents=$(az rest --method GET \
        --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.ResourceHealth/events" \
        --url-parameters "api-version=2022-10-01" \
        --url-parameters "\$filter=eventType eq 'ServiceIssue' and status eq 'Active' and (contains(title, 'NetApp') or contains(summary, 'NetApp') or contains(title, 'Storage'))" \
        --query 'value | length(@)' -o tsv 2>/dev/null || echo "0")
    
    if [[ "$active_incidents" == "0" ]]; then
        log_success "✅ No active service incidents affecting Azure NetApp Files"
    else
        log_alert "🚨 $active_incidents active incident(s) affecting Azure NetApp Files"
        send_alert "ALERT: $active_incidents active service incident(s) affecting Azure NetApp Files"
    fi
    
    echo ""
    echo "💡 Recommendations:"
    echo "   • Monitor this status regularly during critical operations"
    echo "   • Subscribe to Azure Service Health notifications"
    echo "   • Check resource-specific health for detailed insights"
    echo "   • Review planned maintenance schedules"
    echo ""
    echo "🔗 Useful Links:"
    echo "   • Azure Service Health: https://portal.azure.com/#blade/Microsoft_Azure_Health/AzureHealthBrowseBlade"
    echo "   • NetApp Files Documentation: https://docs.microsoft.com/en-us/azure/azure-netapp-files/"
    echo "   • Service Status Page: https://status.azure.com/"
}

# Error handling
handle_error() {
    log_error "An error occurred on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Main script execution
main() {
    log_info "Starting Azure NetApp Files Service Health Monitor..."
    log_info "Script: $SCRIPT_NAME v$SCRIPT_VERSION ($SCRIPT_DATE)"
    
    parse_arguments "$@"
    validate_prerequisites
    
    # Set subscription if provided
    if [[ -n "$SUBSCRIPTION_ID" ]]; then
        az account set --subscription "$SUBSCRIPTION_ID"
    fi
    
    get_service_health_events
    get_resource_health
    generate_summary
    
    log_success "Service health check completed successfully"
}

# Run main function with all arguments
main "$@"
