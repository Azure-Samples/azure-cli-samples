#!/bin/bash
# Azure NetApp Files - Comprehensive Azure Advisor Recommendations
# Complete implementation of all Azure Advisor CLI commands with NetApp Files focus

set -euo pipefail

# Script configuration
SCRIPT_NAME="ANF Azure Advisor Comprehensive"
SCRIPT_VERSION="2.0.0"
LOG_FILE="anf-advisor-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging functions
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

alert() {
    echo -e "${PURPLE}[ALERT] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to check Azure CLI and dependencies
check_dependencies() {
    if ! command -v az >/dev/null 2>&1; then
        error "Azure CLI not found. Please install Azure CLI."
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        error "jq not found. Please install jq for JSON processing."
        exit 1
    fi
    
    if ! az account show >/dev/null 2>&1; then
        error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    log "Dependencies verified successfully"
}

# Function: az advisor recommendation list
# List Azure Advisor recommendations with all options
list_all_recommendations() {
    local category="$1"
    local resource_group="$2"
    local refresh="$3"
    
    info "Listing Azure Advisor recommendations..."
    
    echo -e "\n${BLUE}=== Azure Advisor Recommendations ===${NC}"
    
    local cmd="az advisor recommendation list --output json"
    
    if [ -n "$category" ]; then
        cmd+=" --category $category"
        info "Filtering by category: $category"
    fi
    
    if [ -n "$resource_group" ]; then
        cmd+=" --resource-group $resource_group"
        info "Filtering by resource group: $resource_group"
    fi
    
    if [ "$refresh" = "true" ]; then
        cmd+=" --refresh"
        info "Generating new recommendations..."
    fi
    
    local result=$(eval "$cmd" 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq 'length')" = "0" ]; then
        log "✅ No recommendations found"
        return
    fi
    
    local total_count=$(echo "$result" | jq 'length')
    info "Found $total_count total recommendations"
    
    # Summary by category
    echo -e "\n📊 Recommendations by Category:"
    echo "$result" | jq -r 'group_by(.properties.category) | .[] | "Category: \(.[0].properties.category), Count: \(length)"'
    
    # Summary by impact
    echo -e "\n📊 Recommendations by Impact:"
    echo "$result" | jq -r 'group_by(.properties.impact) | .[] | "Impact: \(.[0].properties.impact), Count: \(length)"'
    
    # Filter for NetApp Files specific recommendations
    echo -e "\n🔵 NetApp Files Specific Recommendations:"
    local netapp_recs=$(echo "$result" | jq '[.[] | select(.properties.impactedValue // "" | test("netapp|NetApp"; "i") or .properties.shortDescription.solution // "" | test("netapp|NetApp"; "i"))]')
    local netapp_count=$(echo "$netapp_recs" | jq 'length')
    
    if [ "$netapp_count" -gt 0 ]; then
        echo "$netapp_recs" | jq -r '.[] | "▶️ [\(.properties.category)] \(.properties.shortDescription.problem) - Impact: \(.properties.impact)"'
        alert "Found $netapp_count NetApp Files specific recommendations"
    else
        log "No NetApp Files specific recommendations found"
    fi
    
    # All recommendations details
    echo -e "\n📝 All Recommendations Details:"
    echo "$result" | jq -r '.[] | "[\(.properties.category)] \(.properties.shortDescription.problem)\n   Solution: \(.properties.shortDescription.solution)\n   Impact: \(.properties.impact), Resource: \(.properties.impactedValue // "N/A")\n"'
}

# Function: az advisor recommendation list with specific categories
list_recommendations_by_category() {
    local category="$1"
    
    echo -e "\n${BLUE}=== $category Recommendations ===${NC}"
    
    local result=$(az advisor recommendation list --category "$category" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq 'length')" = "0" ]; then
        log "✅ No $category recommendations found"
        return
    fi
    
    local count=$(echo "$result" | jq 'length')
    info "Found $count $category recommendations"
    
    echo "$result" | jq -r '.[] | "▶️ \(.properties.shortDescription.problem)\n   Impact: \(.properties.impact), Resource: \(.properties.impactedValue // "N/A")\n   Solution: \(.properties.shortDescription.solution)\n"'
}

# Function: List all recommendation categories
list_all_categories() {
    info "Getting recommendations for all categories..."
    
    local categories=("Cost" "HighAvailability" "Performance" "Security")
    
    for category in "${categories[@]}"; do
        list_recommendations_by_category "$category"
    done
}

# Function: az advisor recommendation disable
# Dismiss Azure Advisor recommendations
disable_recommendation() {
    local recommendation_name="$1"
    local resource_group="$2"
    local days="$3"
    
    if [ -z "$recommendation_name" ]; then
        error "Recommendation name is required for disabling"
        return 1
    fi
    
    info "Disabling recommendation: $recommendation_name"
    
    local cmd="az advisor recommendation disable --name '$recommendation_name'"
    
    if [ -n "$resource_group" ]; then
        cmd+=" --resource-group '$resource_group'"
    fi
    
    if [ -n "$days" ]; then
        cmd+=" --days $days"
        info "Disabling for $days days"
    else
        info "Disabling permanently"
    fi
    
    if eval "$cmd" 2>/dev/null; then
        log "✅ Successfully disabled recommendation: $recommendation_name"
    else
        error "Failed to disable recommendation: $recommendation_name"
        return 1
    fi
}

# Function: az advisor recommendation enable
# Enable Azure Advisor recommendations
enable_recommendation() {
    local recommendation_name="$1"
    local resource_group="$2"
    
    if [ -z "$recommendation_name" ]; then
        error "Recommendation name is required for enabling"
        return 1
    fi
    
    info "Enabling recommendation: $recommendation_name"
    
    local cmd="az advisor recommendation enable --name '$recommendation_name'"
    
    if [ -n "$resource_group" ]; then
        cmd+=" --resource-group '$resource_group'"
    fi
    
    if eval "$cmd" 2>/dev/null; then
        log "✅ Successfully enabled recommendation: $recommendation_name"
    else
        error "Failed to enable recommendation: $recommendation_name"
        return 1
    fi
}

# Function to get recommendations with refresh (generate new ones)
get_fresh_recommendations() {
    info "Generating fresh Azure Advisor recommendations..."
    
    echo -e "\n${BLUE}=== Fresh Recommendations (with refresh) ===${NC}"
    
    local result=$(az advisor recommendation list --refresh --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq 'length')" = "0" ]; then
        log "✅ No fresh recommendations generated"
        return
    fi
    
    local count=$(echo "$result" | jq 'length')
    info "Generated $count fresh recommendations"
    
    # Show only high impact recommendations
    local high_impact=$(echo "$result" | jq '[.[] | select(.properties.impact == "High")]')
    local high_count=$(echo "$high_impact" | jq 'length')
    
    if [ "$high_count" -gt 0 ]; then
        echo -e "\n🔴 High Impact Recommendations:"
        echo "$high_impact" | jq -r '.[] | "▶️ [\(.properties.category)] \(.properties.shortDescription.problem)\n   Resource: \(.properties.impactedValue // "N/A")\n"'
        alert "Found $high_count high impact recommendations"
    fi
    
    # Show medium impact recommendations
    local medium_impact=$(echo "$result" | jq '[.[] | select(.properties.impact == "Medium")]')
    local medium_count=$(echo "$medium_impact" | jq 'length')
    
    if [ "$medium_count" -gt 0 ]; then
        echo -e "\n🟡 Medium Impact Recommendations:"
        echo "$medium_impact" | jq -r '.[] | "▶️ [\(.properties.category)] \(.properties.shortDescription.problem)\n   Resource: \(.properties.impactedValue // "N/A")\n"'
        info "Found $medium_count medium impact recommendations"
    fi
}

# Function to analyze recommendations for NetApp Files resources
analyze_netapp_recommendations() {
    info "Analyzing recommendations specifically for NetApp Files resources..."
    
    echo -e "\n${BLUE}=== NetApp Files Resource Analysis ===${NC}"
    
    # Get all recommendations
    local all_recs=$(az advisor recommendation list --output json 2>/dev/null || echo "[]")
    
    if [ "$all_recs" = "[]" ] || [ "$(echo "$all_recs" | jq 'length')" = "0" ]; then
        log "No recommendations available for analysis"
        return
    fi
    
    # Filter NetApp Files recommendations by multiple criteria
    local netapp_recs=$(echo "$all_recs" | jq '[
        .[] | select(
            (.properties.impactedValue // "" | test("netapp|NetApp|microsoft.netapp"; "i")) or
            (.properties.shortDescription.problem // "" | test("netapp|NetApp"; "i")) or
            (.properties.shortDescription.solution // "" | test("netapp|NetApp"; "i")) or
            (.properties.resourceMetadata.resourceId // "" | test("microsoft.netapp"; "i"))
        )
    ]')
    
    local netapp_count=$(echo "$netapp_recs" | jq 'length')
    
    if [ "$netapp_count" -eq 0 ]; then
        log "✅ No specific recommendations found for NetApp Files resources"
        return
    fi
    
    alert "Found $netapp_count recommendations for NetApp Files resources"
    
    # Categorize NetApp Files recommendations
    echo -e "\n📊 NetApp Files Recommendations by Category:"
    echo "$netapp_recs" | jq -r 'group_by(.properties.category) | .[] | "Category: \(.[0].properties.category), Count: \(length)"'
    
    echo -e "\n📊 NetApp Files Recommendations by Impact:"
    echo "$netapp_recs" | jq -r 'group_by(.properties.impact) | .[] | "Impact: \(.[0].properties.impact), Count: \(length)"'
    
    echo -e "\n📝 NetApp Files Recommendations Details:"
    echo "$netapp_recs" | jq -r '.[] | "🔵 [\(.properties.category)|\(.properties.impact)] \(.properties.shortDescription.problem)\n   💡 Solution: \(.properties.shortDescription.solution)\n   📦 Resource: \(.properties.impactedValue // .properties.resourceMetadata.resourceId // "N/A")\n   🔗 Resource ID: \(.id)\n"'
    
    # Save NetApp Files specific recommendations
    local anf_report="anf-advisor-recommendations-$(date +%Y%m%d-%H%M%S).json"
    echo "$netapp_recs" > "$anf_report"
    log "NetApp Files recommendations saved to: $anf_report"
}

# Function to bulk disable low priority recommendations
bulk_disable_low_priority() {
    local days="$1"
    
    info "Bulk disabling low priority recommendations..."
    
    local low_priority_recs=$(az advisor recommendation list --output json 2>/dev/null | jq -r '.[] | select(.properties.impact == "Low") | .name')
    
    if [ -z "$low_priority_recs" ]; then
        log "No low priority recommendations found to disable"
        return
    fi
    
    local count=0
    while IFS= read -r rec_name; do
        if [ -n "$rec_name" ]; then
            if disable_recommendation "$rec_name" "" "$days"; then
                ((count++))
            fi
        fi
    done <<< "$low_priority_recs"
    
    log "Bulk disabled $count low priority recommendations"
}

# Function to bulk enable previously disabled recommendations
bulk_enable_recommendations() {
    info "Bulk enabling previously disabled recommendations..."
    
    # This is a placeholder as Azure CLI doesn't provide a direct way to list disabled recommendations
    # In practice, you would maintain a list of disabled recommendations
    
    warn "Bulk enable requires a list of previously disabled recommendations"
    warn "Consider maintaining a log of disabled recommendations for bulk re-enabling"
}

# Function to generate comprehensive advisor report
generate_advisor_report() {
    local report_file="anf-advisor-comprehensive-report-$(date +%Y%m%d-%H%M%S).json"
    
    info "Generating comprehensive Azure Advisor report..."
    
    # Get fresh recommendations
    local all_recs=$(az advisor recommendation list --refresh --output json 2>/dev/null || echo "[]")
    
    echo "{" > "$report_file"
    echo "  \"report_metadata\": {" >> "$report_file"
    echo "    \"generated_at\": \"$(date -Iseconds)\"," >> "$report_file"
    echo "    \"script_version\": \"$SCRIPT_VERSION\"," >> "$report_file"
    echo "    \"scope\": \"Azure Advisor - NetApp Files Focus\"" >> "$report_file"
    echo "  }," >> "$report_file"
    
    echo "  \"summary\": {" >> "$report_file"
    local total_count=$(echo "$all_recs" | jq 'length')
    echo "    \"total_recommendations\": $total_count," >> "$report_file"
    
    local high_count=$(echo "$all_recs" | jq '[.[] | select(.properties.impact == "High")] | length')
    echo "    \"high_impact\": $high_count," >> "$report_file"
    
    local medium_count=$(echo "$all_recs" | jq '[.[] | select(.properties.impact == "Medium")] | length')
    echo "    \"medium_impact\": $medium_count," >> "$report_file"
    
    local low_count=$(echo "$all_recs" | jq '[.[] | select(.properties.impact == "Low")] | length')
    echo "    \"low_impact\": $low_count," >> "$report_file"
    
    local netapp_count=$(echo "$all_recs" | jq '[.[] | select((.properties.impactedValue // "" | test("netapp|NetApp|microsoft.netapp"; "i")) or (.properties.shortDescription.problem // "" | test("netapp|NetApp"; "i")))] | length')
    echo "    \"netapp_files_specific\": $netapp_count" >> "$report_file"
    echo "  }," >> "$report_file"
    
    echo "  \"recommendations_by_category\": {" >> "$report_file"
    local cost_recs=$(echo "$all_recs" | jq '[.[] | select(.properties.category == "Cost")]')
    echo "    \"cost\": $cost_recs," >> "$report_file"
    
    local ha_recs=$(echo "$all_recs" | jq '[.[] | select(.properties.category == "HighAvailability")]')
    echo "    \"high_availability\": $ha_recs," >> "$report_file"
    
    local perf_recs=$(echo "$all_recs" | jq '[.[] | select(.properties.category == "Performance")]')
    echo "    \"performance\": $perf_recs," >> "$report_file"
    
    local sec_recs=$(echo "$all_recs" | jq '[.[] | select(.properties.category == "Security")]')
    echo "    \"security\": $sec_recs" >> "$report_file"
    echo "  }," >> "$report_file"
    
    local netapp_recs=$(echo "$all_recs" | jq '[.[] | select((.properties.impactedValue // "" | test("netapp|NetApp|microsoft.netapp"; "i")) or (.properties.shortDescription.problem // "" | test("netapp|NetApp"; "i")))]')
    echo "  \"netapp_files_recommendations\": $netapp_recs" >> "$report_file"
    echo "}" >> "$report_file"
    
    log "Comprehensive advisor report generated: $report_file"
    
    # Display summary
    echo -e "\n${GREEN}=== Advisor Report Summary ===${NC}"
    echo "📊 Total Recommendations: $total_count"
    echo "🔴 High Impact: $high_count"
    echo "🟡 Medium Impact: $medium_count"
    echo "🟢 Low Impact: $low_count"
    echo "🔵 NetApp Files Specific: $netapp_count"
    echo "📄 Detailed Report: $report_file"
}

# Function to setup advisor monitoring
setup_advisor_monitoring() {
    local webhook_url="$1"
    local threshold="${2:-5}"
    
    if [ -z "$webhook_url" ]; then
        info "No webhook URL provided, skipping advisor monitoring setup"
        return
    fi
    
    info "Setting up Azure Advisor monitoring..."
    
    cat > "anf-advisor-monitor-daemon.sh" << 'EOF'
#!/bin/bash
# Azure Advisor monitoring daemon for NetApp Files

WEBHOOK_URL="$1"
THRESHOLD="${2:-5}"
CHECK_INTERVAL="${3:-3600}" # 1 hour default

while true; do
    # Get current high impact recommendations
    HIGH_IMPACT=$(az advisor recommendation list --output json 2>/dev/null | jq '[.[] | select(.properties.impact == "High")] | length')
    
    if [ "$HIGH_IMPACT" -ge "$THRESHOLD" ]; then
        MESSAGE="⚠️ ADVISOR ALERT: $HIGH_IMPACT high impact recommendations found (threshold: $THRESHOLD)"
        curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL" 2>/dev/null || echo "Failed to send alert"
    fi
    
    # Check for NetApp Files specific high impact recommendations
    NETAPP_HIGH=$(az advisor recommendation list --output json 2>/dev/null | jq '[.[] | select(.properties.impact == "High" and ((.properties.impactedValue // "" | test("netapp|NetApp"; "i")) or (.properties.shortDescription.problem // "" | test("netapp|NetApp"; "i"))))] | length')
    
    if [ "$NETAPP_HIGH" -gt 0 ]; then
        MESSAGE="🔵 ANF ADVISOR ALERT: $NETAPP_HIGH high impact recommendations for NetApp Files resources"
        curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL" 2>/dev/null || echo "Failed to send alert"
    fi
    
    sleep "$CHECK_INTERVAL"
done
EOF
    
    chmod +x "anf-advisor-monitor-daemon.sh"
    log "Advisor monitoring daemon created: anf-advisor-monitor-daemon.sh"
    log "To start monitoring: ./anf-advisor-monitor-daemon.sh '$webhook_url' $threshold &"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --list [--category CATEGORY] [--resource-group RG] [--refresh]"
    echo "                             List Azure Advisor recommendations"
    echo "  --all-categories           Get recommendations for all categories"
    echo "  --cost                     Get Cost recommendations only"
    echo "  --high-availability        Get HighAvailability recommendations only"
    echo "  --performance              Get Performance recommendations only"
    echo "  --security                 Get Security recommendations only"
    echo "  --fresh                    Generate fresh recommendations with refresh"
    echo "  --netapp-analysis          Analyze recommendations for NetApp Files"
    echo "  --disable NAME [--rg RG] [--days DAYS]"
    echo "                             Disable a specific recommendation"
    echo "  --enable NAME [--rg RG]    Enable a specific recommendation"
    echo "  --bulk-disable-low [--days DAYS]"
    echo "                             Bulk disable low priority recommendations"
    echo "  --bulk-enable              Bulk enable previously disabled recommendations"
    echo "  --generate-report          Generate comprehensive advisor report"
    echo "  --setup-monitoring URL [--threshold NUM]"
    echo "                             Setup monitoring with webhook alerts"
    echo "  --help                     Show this help message"
    echo ""
    echo "Categories: Cost, HighAvailability, Performance, Security"
    echo ""
    echo "Examples:"
    echo "  $0 --list --category Cost --refresh"
    echo "  $0 --netapp-analysis"
    echo "  $0 --disable 'MyRecommendation' --days 30"
    echo "  $0 --enable 'MyRecommendation'"
    echo "  $0 --bulk-disable-low --days 7"
    echo "  $0 --generate-report"
    echo "  $0 --setup-monitoring https://hooks.slack.com/your/webhook/url --threshold 3"
}

# Main function
main() {
    log "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    
    check_dependencies
    
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    local category=""
    local resource_group=""
    local refresh="false"
    local recommendation_name=""
    local days=""
    local webhook_url=""
    local threshold="5"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                shift
                # Parse optional sub-arguments
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    case $1 in
                        --category)
                            category="$2"
                            shift 2
                            ;;
                        --resource-group)
                            resource_group="$2"
                            shift 2
                            ;;
                        --refresh)
                            refresh="true"
                            shift
                            ;;
                        *)
                            shift
                            ;;
                    esac
                done
                list_all_recommendations "$category" "$resource_group" "$refresh"
                ;;
            --all-categories)
                list_all_categories
                shift
                ;;
            --cost)
                list_recommendations_by_category "Cost"
                shift
                ;;
            --high-availability)
                list_recommendations_by_category "HighAvailability"
                shift
                ;;
            --performance)
                list_recommendations_by_category "Performance"
                shift
                ;;
            --security)
                list_recommendations_by_category "Security"
                shift
                ;;
            --fresh)
                get_fresh_recommendations
                shift
                ;;
            --netapp-analysis)
                analyze_netapp_recommendations
                shift
                ;;
            --disable)
                recommendation_name="$2"
                shift 2
                # Parse optional sub-arguments
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    case $1 in
                        --rg)
                            resource_group="$2"
                            shift 2
                            ;;
                        --days)
                            days="$2"
                            shift 2
                            ;;
                        *)
                            shift
                            ;;
                    esac
                done
                disable_recommendation "$recommendation_name" "$resource_group" "$days"
                ;;
            --enable)
                recommendation_name="$2"
                shift 2
                # Parse optional sub-arguments
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    case $1 in
                        --rg)
                            resource_group="$2"
                            shift 2
                            ;;
                        *)
                            shift
                            ;;
                    esac
                done
                enable_recommendation "$recommendation_name" "$resource_group"
                ;;
            --bulk-disable-low)
                shift
                # Parse optional sub-arguments
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    case $1 in
                        --days)
                            days="$2"
                            shift 2
                            ;;
                        *)
                            shift
                            ;;
                    esac
                done
                bulk_disable_low_priority "$days"
                ;;
            --bulk-enable)
                bulk_enable_recommendations
                shift
                ;;
            --generate-report)
                generate_advisor_report
                shift
                ;;
            --setup-monitoring)
                webhook_url="$2"
                shift 2
                # Parse optional sub-arguments
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    case $1 in
                        --threshold)
                            threshold="$2"
                            shift 2
                            ;;
                        *)
                            shift
                            ;;
                    esac
                done
                setup_advisor_monitoring "$webhook_url" "$threshold"
                ;;
            --help)
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
    
    log "$SCRIPT_NAME completed successfully"
}

# Run main function with all arguments
main "$@"
