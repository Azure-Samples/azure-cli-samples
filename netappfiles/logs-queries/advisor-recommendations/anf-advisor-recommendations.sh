#!/bin/bash
# Azure NetApp Files - Azure Advisor Recommendations
# Retrieves and analyzes Azure Advisor recommendations for NetApp Files resources

set -euo pipefail

# Script configuration
SCRIPT_NAME="anf-advisor-recommendations"
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="$(date +%Y-%m-%d)"

# Default values
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
CATEGORY="all"
OUTPUT_FORMAT="table"
EXPORT_FILE=""
SEVERITY_FILTER=""

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

log_highlight() {
    echo -e "${PURPLE}[ADVISOR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Azure NetApp Files - Azure Advisor Recommendations

Retrieves and analyzes Azure Advisor recommendations specifically for NetApp Files resources.

Usage: $0 [OPTIONS]

OPTIONS:
    -s, --subscription      Subscription ID (optional, uses default if not specified)
    -g, --resource-group    Resource group to analyze (optional, analyzes all if not specified)
    -c, --category         Recommendation category (Cost, Security, Reliability, Performance, all) (default: all)
    -o, --output           Output format (table, json, tsv) (default: table)
    -e, --export           Export results to file (JSON format)
    --severity             Filter by severity (High, Medium, Low)
    --cost-only            Show only cost optimization recommendations
    --security-only        Show only security recommendations
    --performance-only     Show only performance recommendations
    --reliability-only     Show only reliability recommendations
    -h, --help             Show this help message

Examples:
    $0                                          # Get all recommendations for default subscription
    $0 -g myNetAppRG -c Cost                   # Get cost recommendations for specific RG
    $0 --cost-only -o json                     # Get cost recommendations in JSON format
    $0 -s mySubId --export /tmp/advisor.json   # Export all recommendations to file
    $0 --severity High --performance-only      # Get high-severity performance recommendations

Recommendation Categories:
    • Cost: Recommendations to optimize spending
    • Security: Security best practices and configurations
    • Reliability: High availability and disaster recovery guidance
    • Performance: Performance optimization suggestions
    • OperationalExcellence: Operational best practices

Severity Levels:
    • High: Critical recommendations requiring immediate attention
    • Medium: Important recommendations to address soon
    • Low: Optional optimizations and enhancements

EOF
}

# Parse command line arguments
parse_arguments() {
    COST_ONLY=false
    SECURITY_ONLY=false
    PERFORMANCE_ONLY=false
    RELIABILITY_ONLY=false
    
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
            -c|--category)
                CATEGORY="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -e|--export)
                EXPORT_FILE="$2"
                shift 2
                ;;
            --severity)
                SEVERITY_FILTER="$2"
                shift 2
                ;;
            --cost-only)
                COST_ONLY=true
                CATEGORY="Cost"
                shift
                ;;
            --security-only)
                SECURITY_ONLY=true
                CATEGORY="Security"
                shift
                ;;
            --performance-only)
                PERFORMANCE_ONLY=true
                CATEGORY="Performance"
                shift
                ;;
            --reliability-only)
                RELIABILITY_ONLY=true
                CATEGORY="Reliability"
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
    
    # Validate category
    if [[ "$CATEGORY" != "all" && "$CATEGORY" != "Cost" && "$CATEGORY" != "Security" && "$CATEGORY" != "Reliability" && "$CATEGORY" != "Performance" && "$CATEGORY" != "OperationalExcellence" ]]; then
        log_error "Invalid category. Must be one of: all, Cost, Security, Reliability, Performance, OperationalExcellence"
        exit 1
    fi
    
    # Validate severity if specified
    if [[ -n "$SEVERITY_FILTER" && "$SEVERITY_FILTER" != "High" && "$SEVERITY_FILTER" != "Medium" && "$SEVERITY_FILTER" != "Low" ]]; then
        log_error "Invalid severity. Must be one of: High, Medium, Low"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Get NetApp Files resources
get_netapp_resources() {
    log_info "Discovering NetApp Files resources..."
    
    local query_scope=""
    if [[ -n "$RESOURCE_GROUP" ]]; then
        query_scope="-g $RESOURCE_GROUP"
    fi
    
    # Get NetApp accounts
    local accounts
    accounts=$(az netappfiles account list $query_scope --query '[].id' -o tsv 2>/dev/null || echo "")
    
    if [[ -z "$accounts" ]]; then
        log_warning "No NetApp Files accounts found"
        return 1
    fi
    
    local account_count
    account_count=$(echo "$accounts" | wc -l)
    log_success "Found $account_count NetApp Files account(s)"
    
    # Store resource IDs for filtering
    echo "$accounts" > /tmp/netapp_resources.txt
    return 0
}

# Get Azure Advisor recommendations
get_advisor_recommendations() {
    log_info "Retrieving Azure Advisor recommendations..."
    
    # Build the query
    local query_cmd="az advisor recommendation list"
    
    if [[ "$CATEGORY" != "all" ]]; then
        query_cmd="$query_cmd --category $CATEGORY"
    fi
    
    if [[ -n "$RESOURCE_GROUP" ]]; then
        query_cmd="$query_cmd --resource-group $RESOURCE_GROUP"
    fi
    
    # Execute initial query
    local all_recommendations
    all_recommendations=$(eval "$query_cmd" --query '[].{
        Id: recommendationId,
        Category: category,
        Impact: impact,
        ImpactedField: impactedField,
        ImpactedValue: impactedValue,
        ShortDescription: shortDescription.problem,
        Solution: shortDescription.solution,
        ResourceId: resourceMetadata.resourceId,
        ResourceName: resourceMetadata.resourceId,
        LastUpdated: lastUpdated
    }' -o json 2>/dev/null)
    
    if [[ -z "$all_recommendations" || "$all_recommendations" == "[]" ]]; then
        log_info "No Azure Advisor recommendations found"
        return 0
    fi
    
    # Filter for NetApp Files related recommendations
    local netapp_recommendations
    if [[ -f "/tmp/netapp_resources.txt" ]]; then
        # Filter by NetApp resource IDs
        netapp_recommendations=$(echo "$all_recommendations" | jq --argjson resources "$(cat /tmp/netapp_resources.txt | jq -R . | jq -s .)" '
            map(select(.ResourceId as $rid | $resources | any(. == $rid)))
        ')
    else
        # Filter by keywords in description
        netapp_recommendations=$(echo "$all_recommendations" | jq '
            map(select(
                (.ShortDescription | ascii_downcase | contains("netapp")) or
                (.Solution | ascii_downcase | contains("netapp")) or
                (.ImpactedValue | ascii_downcase | contains("netapp")) or
                (.ResourceId | ascii_downcase | contains("netapp"))
            ))
        ')
    fi
    
    # Apply severity filter if specified
    if [[ -n "$SEVERITY_FILTER" ]]; then
        netapp_recommendations=$(echo "$netapp_recommendations" | jq --arg severity "$SEVERITY_FILTER" '
            map(select(.Impact == $severity))
        ')
    fi
    
    # Display results
    if [[ -z "$netapp_recommendations" || "$netapp_recommendations" == "[]" ]]; then
        log_info "No NetApp Files specific recommendations found"
        return 0
    fi
    
    local rec_count
    rec_count=$(echo "$netapp_recommendations" | jq 'length')
    log_highlight "Found $rec_count NetApp Files recommendation(s)"
    
    # Output recommendations
    case "$OUTPUT_FORMAT" in
        "json")
            echo "$netapp_recommendations"
            ;;
        "table")
            echo "$netapp_recommendations" | jq -r '
                ["CATEGORY", "IMPACT", "PROBLEM", "SOLUTION", "RESOURCE"],
                ["--------", "------", "-------", "--------", "--------"],
                (.[] | [.Category, .Impact, .ShortDescription, .Solution, (.ResourceName | split("/")[-1])])
                | @tsv
            ' | column -t -s $'\t'
            ;;
        "tsv")
            echo "$netapp_recommendations" | jq -r '
                ["Category", "Impact", "Problem", "Solution", "Resource", "LastUpdated"],
                (.[] | [.Category, .Impact, .ShortDescription, .Solution, (.ResourceName | split("/")[-1]), .LastUpdated])
                | @tsv
            '
            ;;
    esac
    
    # Export to file if requested
    if [[ -n "$EXPORT_FILE" ]]; then
        echo "$netapp_recommendations" > "$EXPORT_FILE"
        log_success "Results exported to: $EXPORT_FILE"
    fi
    
    # Store recommendations for analysis
    echo "$netapp_recommendations" > /tmp/netapp_advisor_recommendations.json
    
    return 0
}

# Analyze recommendations by category
analyze_recommendations() {
    if [[ ! -f "/tmp/netapp_advisor_recommendations.json" ]]; then
        return 0
    fi
    
    log_info "Analyzing recommendations..."
    
    local recommendations
    recommendations=$(cat /tmp/netapp_advisor_recommendations.json)
    
    if [[ "$recommendations" == "[]" ]]; then
        return 0
    fi
    
    echo ""
    echo "📊 Recommendation Analysis"
    echo "========================="
    
    # Count by category
    echo ""
    echo "🏷️  By Category:"
    echo "$recommendations" | jq -r 'group_by(.Category) | .[] | "\(.length) \(.[0].Category) recommendations"' | sed 's/^/   • /'
    
    # Count by impact
    echo ""
    echo "⚡ By Impact Level:"
    echo "$recommendations" | jq -r 'group_by(.Impact) | .[] | "\(.length) \(.[0].Impact) impact recommendations"' | sed 's/^/   • /'
    
    # High impact recommendations
    local high_impact
    high_impact=$(echo "$recommendations" | jq '[.[] | select(.Impact == "High")] | length')
    
    if [[ "$high_impact" -gt 0 ]]; then
        echo ""
        log_warning "🚨 $high_impact HIGH IMPACT recommendation(s) require immediate attention!"
        echo "$recommendations" | jq -r '.[] | select(.Impact == "High") | "   ⚠️  \(.ShortDescription)"'
    fi
    
    # Cost recommendations
    local cost_recs
    cost_recs=$(echo "$recommendations" | jq '[.[] | select(.Category == "Cost")] | length')
    
    if [[ "$cost_recs" -gt 0 ]]; then
        echo ""
        log_info "💰 Cost Optimization Opportunities:"
        echo "$recommendations" | jq -r '.[] | select(.Category == "Cost") | "   💡 \(.ShortDescription)"'
    fi
    
    # Security recommendations
    local security_recs
    security_recs=$(echo "$recommendations" | jq '[.[] | select(.Category == "Security")] | length')
    
    if [[ "$security_recs" -gt 0 ]]; then
        echo ""
        log_info "🔒 Security Recommendations:"
        echo "$recommendations" | jq -r '.[] | select(.Category == "Security") | "   🛡️  \(.ShortDescription)"'
    fi
}

# Generate actionable summary
generate_summary() {
    log_info "Generating actionable summary..."
    
    echo ""
    echo "📋 Azure Advisor Summary for NetApp Files"
    echo "=========================================="
    echo "📅 Report Date: $(date)"
    echo "🔍 Scope: ${RESOURCE_GROUP:-All Resource Groups}"
    echo "📊 Category: $CATEGORY"
    echo "🎯 Subscription: ${SUBSCRIPTION_ID:-Default}"
    
    if [[ -f "/tmp/netapp_advisor_recommendations.json" ]]; then
        local total_recs
        total_recs=$(cat /tmp/netapp_advisor_recommendations.json | jq 'length')
        echo "📈 Total Recommendations: $total_recs"
        
        if [[ "$total_recs" -gt 0 ]]; then
            echo ""
            echo "🎯 Next Steps:"
            echo "   1. Review high-impact recommendations first"
            echo "   2. Implement cost optimization suggestions"
            echo "   3. Address security recommendations"
            echo "   4. Schedule performance optimizations"
            echo "   5. Monitor recommendation status regularly"
        else
            echo ""
            log_success "✅ No outstanding recommendations - NetApp Files resources are well-optimized!"
        fi
    else
        echo "📈 Total Recommendations: 0"
    fi
    
    echo ""
    echo "🔗 Additional Resources:"
    echo "   • Azure Advisor Portal: https://portal.azure.com/#blade/Microsoft_Azure_Expert/AdvisorMenuBlade"
    echo "   • NetApp Files Best Practices: https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-best-practices"
    echo "   • Cost Management: https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview"
    
    # Cleanup temp files
    rm -f /tmp/netapp_resources.txt /tmp/netapp_advisor_recommendations.json
}

# Error handling
handle_error() {
    log_error "An error occurred on line $1"
    # Cleanup temp files
    rm -f /tmp/netapp_resources.txt /tmp/netapp_advisor_recommendations.json
    exit 1
}

trap 'handle_error $LINENO' ERR

# Main script execution
main() {
    log_info "Starting Azure Advisor analysis for NetApp Files..."
    log_info "Script: $SCRIPT_NAME v$SCRIPT_VERSION ($SCRIPT_DATE)"
    
    parse_arguments "$@"
    validate_prerequisites
    
    # Set subscription if provided
    if [[ -n "$SUBSCRIPTION_ID" ]]; then
        az account set --subscription "$SUBSCRIPTION_ID"
    fi
    
    # Get current subscription for display
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    
    get_netapp_resources
    get_advisor_recommendations
    analyze_recommendations
    generate_summary
    
    log_success "Azure Advisor analysis completed successfully"
}

# Run main function with all arguments
main "$@"
