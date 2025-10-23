#!/bin/bash
# Azure NetApp Files - Comprehensive Service Health Monitoring
# Monitors Azure Service Health with all available queries and Azure Resource Graph integration

set -euo pipefail

# Script configuration
SCRIPT_NAME="ANF Service Health Comprehensive Monitor"
SCRIPT_VERSION="2.0.0"
LOG_FILE="anf-service-health-$(date +%Y%m%d-%H%M%S).log"

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

# Function to get active service health events by subscription
get_active_service_health_events() {
    info "Getting active Service Health events by subscription..."
    
    local query='ServiceHealthResources
| where type =~ "Microsoft.ResourceHealth/events"
| extend eventType = tostring(properties.EventType), status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = properties.ImpactMitigationTime
| where eventType == "ServiceIssue" and status == "Active"
| summarize count(subscriptionId) by name'
    
    echo -e "\n${BLUE}=== Active Service Health Events by Subscription ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No active service health events found"
    else
        echo "$result" | jq -r '.data[] | "Event: \(.name), Affected Subscriptions: \(.count_subscriptionId)"'
        warn "Found active service health events affecting NetApp Files"
    fi
}

# Function to get all active health advisory events
get_active_health_advisories() {
    info "Getting all active health advisory events..."
    
    local query='ServiceHealthResources
| where type =~ "Microsoft.ResourceHealth/events"
| extend eventType = properties.EventType, status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = todatetime(tolong(properties.ImpactMitigationTime))
| where eventType == "HealthAdvisory" and impactMitigationTime > now()'
    
    echo -e "\n${BLUE}=== Active Health Advisory Events ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No active health advisory events found"
    else
        echo "$result" | jq -r '.data[] | "Advisory: \(.description), Priority: \(.priority), Status: \(.status)"'
        info "Found $(echo "$result" | jq '.data | length') active health advisory events"
    fi
}

# Function to get upcoming service retirement events
get_upcoming_retirement_events() {
    info "Getting upcoming service retirement events..."
    
    local query='ServiceHealthResources
| where type =~ "Microsoft.ResourceHealth/events"
| extend eventType = properties.EventType, eventSubType = properties.EventSubType
| where eventType == "HealthAdvisory" and eventSubType == "Retirement"
| extend status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = todatetime(tolong(properties.ImpactStartTime)), impactMitigationTime = todatetime(tolong(properties.ImpactMitigationTime)), impact = properties.Impact
| where impactMitigationTime > datetime(now)
| project trackingId, subscriptionId, status, eventType, eventSubType, summary, description, priority, impactStartTime, impactMitigationTime, impact'
    
    echo -e "\n${BLUE}=== Upcoming Service Retirement Events ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No upcoming service retirement events found"
    else
        echo "$result" | jq -r '.data[] | "Retirement: \(.description), Impact Date: \(.impactMitigationTime), Priority: \(.priority)"'
        alert "Found $(echo "$result" | jq '.data | length') upcoming service retirement events"
    fi
}

# Function to get all active planned maintenance events
get_active_planned_maintenance() {
    info "Getting all active planned maintenance events..."
    
    local query='ServiceHealthResources
| where type =~ "Microsoft.ResourceHealth/events"
| extend eventType = properties.EventType, status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = todatetime(tolong(properties.ImpactMitigationTime))
| where eventType == "PlannedMaintenance" and impactMitigationTime > now()'
    
    echo -e "\n${BLUE}=== Active Planned Maintenance Events ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No active planned maintenance events found"
    else
        echo "$result" | jq -r '.data[] | "Maintenance: \(.description), End Time: \(.impactMitigationTime), Priority: \(.priority)"'
        info "Found $(echo "$result" | jq '.data | length') active planned maintenance events"
    fi
}

# Function to get all active service health events (comprehensive)
get_all_active_service_health() {
    info "Getting all active Service Health events..."
    
    local query='ServiceHealthResources
| where type =~ "Microsoft.ResourceHealth/events"
| extend eventType = properties.EventType, status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = properties.ImpactMitigationTime
| where (eventType in ("HealthAdvisory", "SecurityAdvisory", "PlannedMaintenance") and impactMitigationTime > now()) or (eventType == "ServiceIssue" and status == "Active")'
    
    echo -e "\n${BLUE}=== All Active Service Health Events ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No active service health events found"
    else
        echo -e "\n📊 Event Summary:"
        echo "$result" | jq -r '.data | group_by(.eventType) | .[] | "Type: \(.[0].eventType), Count: \(length)"'
        
        echo -e "\n📝 Event Details:"
        echo "$result" | jq -r '.data[] | "[\(.eventType)] \(.description) - Priority: \(.priority), Status: \(.status)"'
        
        info "Found $(echo "$result" | jq '.data | length') total active service health events"
    fi
}

# Function to get all active service issue events (outages)
get_active_service_issues() {
    info "Getting all active service issue events (outages)..."
    
    local query='ServiceHealthResources
| where type =~ "Microsoft.ResourceHealth/events"
| extend eventType = properties.EventType, status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = properties.ImpactMitigationTime
| where eventType == "ServiceIssue" and status == "Active"'
    
    echo -e "\n${BLUE}=== Active Service Issue Events (Outages) ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No active service issue events found"
    else
        echo "$result" | jq -r '.data[] | "🚨 OUTAGE: \(.description), Tracking ID: \(.trackingId), Priority: \(.priority)"'
        alert "Found $(echo "$result" | jq '.data | length') active service issue events (outages)"
    fi
}

# Function to get confirmed impacted resources
get_confirmed_impacted_resources() {
    info "Getting confirmed impacted resources..."
    
    local query='ServiceHealthResources
| where type == "microsoft.resourcehealth/events/impactedresources"
| extend TrackingId = split(split(id, "/events/", 1)[0], "/impactedResources", 0)[0]
| extend p = parse_json(properties)
| project subscriptionId, TrackingId, resourceName= p.resourceName, resourceGroup=p.resourceGroup, resourceType=p.targetResourceType, details = p, id'
    
    echo -e "\n${BLUE}=== Confirmed Impacted Resources ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No confirmed impacted resources found"
    else
        echo -e "\n📊 Impacted Resources Summary:"
        echo "$result" | jq -r '.data | group_by(.resourceType) | .[] | "Resource Type: \(.[0].resourceType), Count: \(length)"'
        
        echo -e "\n📝 Impacted Resources Details:"
        echo "$result" | jq -r '.data[] | "Resource: \(.resourceName) (\(.resourceType)) in RG: \(.resourceGroup)"'
        
        alert "Found $(echo "$result" | jq '.data | length') confirmed impacted resources"
    fi
}

# Function to get confirmed impacted resources with details
get_impacted_resources_with_details() {
    info "Getting confirmed impacted resources with extended details..."
    
    local query='ServiceHealthResources
| where type == "microsoft.resourcehealth/events/impactedresources"
| extend TrackingId = split(split(id, "/events/", 1)[0], "/impactedResources", 0)[0]
| extend p = parse_json(properties)
| project subscriptionId, TrackingId, targetResourceId= tostring(p.targetResourceId), details = p
| join kind=inner (
    Resources
    )
    on $left.targetResourceId == $right.id'
    
    echo -e "\n${BLUE}=== Impacted Resources with Extended Details ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No impacted resources with extended details found"
    else
        echo "$result" | jq -r '.data[] | "Resource: \(.name) (\(.type)) in \(.location), Status: \(.details)"'
        info "Found $(echo "$result" | jq '.data | length') impacted resources with extended details"
    fi
}

# Function to filter events for NetApp Files specifically
filter_netapp_files_events() {
    info "Filtering events specifically for Azure NetApp Files..."
    
    local query='ServiceHealthResources
| where type =~ "Microsoft.ResourceHealth/events"
| extend eventType = properties.EventType, status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = properties.ImpactMitigationTime, impactedServices = properties.Impact.ImpactedServices
| where (eventType in ("HealthAdvisory", "SecurityAdvisory", "PlannedMaintenance") and impactMitigationTime > now()) or (eventType == "ServiceIssue" and status == "Active")
| mv-expand impactedService = impactedServices
| where impactedService.ServiceName =~ "Azure NetApp Files" or description contains "NetApp" or summary contains "NetApp"'
    
    echo -e "\n${BLUE}=== Azure NetApp Files Specific Events ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No Azure NetApp Files specific events found"
    else
        echo "$result" | jq -r '.data[] | "🔵 ANF EVENT: [\(.eventType)] \(.description) - Priority: \(.priority), Status: \(.status)"'
        alert "Found $(echo "$result" | jq '.data | length') Azure NetApp Files specific events"
    fi
}

# Function to get resource health for NetApp Files resources
get_netapp_files_resource_health() {
    info "Getting resource health for Azure NetApp Files resources..."
    
    local query='HealthResources
| where type =~ "microsoft.resourcehealth/availabilitystatuses"
| where tostring(properties.targetResourceType) =~ "microsoft.netapp"
| summarize by ResourceId = tolower(tostring(properties.targetResourceId)), AvailabilityState = tostring(properties.availabilityState), ReasonType = tostring(properties.reasonType)'
    
    echo -e "\n${BLUE}=== Azure NetApp Files Resource Health ===${NC}"
    
    local result=$(az graph query --query "$query" --output json 2>/dev/null || echo "[]")
    
    if [ "$result" = "[]" ] || [ "$(echo "$result" | jq '.data | length')" = "0" ]; then
        log "✅ No Azure NetApp Files resources found or all are healthy"
    else
        echo -e "\n📊 Health Summary:"
        echo "$result" | jq -r '.data | group_by(.AvailabilityState) | .[] | "State: \(.[0].AvailabilityState), Count: \(length)"'
        
        echo -e "\n📝 Resources Not Available:"
        echo "$result" | jq -r '.data[] | select(.AvailabilityState != "Available") | "❌ \(.ResourceId) - State: \(.AvailabilityState), Reason: \(.ReasonType)"'
        
        local unhealthy_count=$(echo "$result" | jq '.data[] | select(.AvailabilityState != "Available")' | jq -s 'length')
        if [ "$unhealthy_count" -gt 0 ]; then
            alert "Found $unhealthy_count unhealthy Azure NetApp Files resources"
        else
            log "All Azure NetApp Files resources are available"
        fi
    fi
}

# Function to generate comprehensive health report
generate_health_report() {
    local report_file="anf-health-report-$(date +%Y%m%d-%H%M%S).json"
    
    info "Generating comprehensive health report..."
    
    echo "{" > "$report_file"
    echo "  \"report_metadata\": {" >> "$report_file"
    echo "    \"generated_at\": \"$(date -Iseconds)\"," >> "$report_file"
    echo "    \"script_version\": \"$SCRIPT_VERSION\"," >> "$report_file"
    echo "    \"scope\": \"Azure NetApp Files Service Health\"" >> "$report_file"
    echo "  }," >> "$report_file"
    
    # Get all data and add to report
    echo "  \"active_service_events\": " >> "$report_file"
    az graph query --query 'ServiceHealthResources | where type =~ "Microsoft.ResourceHealth/events" | where (properties.EventType in ("HealthAdvisory", "SecurityAdvisory", "PlannedMaintenance") and properties.ImpactMitigationTime > now()) or (properties.EventType == "ServiceIssue" and properties.Status == "Active")' --output json 2>/dev/null | jq '.data' >> "$report_file"
    
    echo "  ," >> "$report_file"
    echo "  \"netapp_resource_health\": " >> "$report_file"
    az graph query --query 'HealthResources | where type =~ "microsoft.resourcehealth/availabilitystatuses" | where tostring(properties.targetResourceType) =~ "microsoft.netapp"' --output json 2>/dev/null | jq '.data' >> "$report_file"
    
    echo "}" >> "$report_file"
    
    log "Health report generated: $report_file"
    
    # Generate summary
    echo -e "\n${GREEN}=== Health Report Summary ===${NC}"
    local active_events=$(az graph query --query 'ServiceHealthResources | where type =~ "Microsoft.ResourceHealth/events" | where (properties.EventType in ("HealthAdvisory", "SecurityAdvisory", "PlannedMaintenance") and properties.ImpactMitigationTime > now()) or (properties.EventType == "ServiceIssue" and properties.Status == "Active") | count' --output json 2>/dev/null | jq -r '.data[0].count_')
    local anf_resources=$(az graph query --query 'HealthResources | where type =~ "microsoft.resourcehealth/availabilitystatuses" | where tostring(properties.targetResourceType) =~ "microsoft.netapp" | count' --output json 2>/dev/null | jq -r '.data[0].count_')
    
    echo "📊 Active Service Events: ${active_events:-0}"
    echo "📊 NetApp Files Resources Monitored: ${anf_resources:-0}"
    echo "📄 Detailed Report: $report_file"
}

# Function to setup monitoring with alerts
setup_monitoring_alerts() {
    local webhook_url="$1"
    
    if [ -z "$webhook_url" ]; then
        info "No webhook URL provided, skipping alert setup"
        return
    fi
    
    info "Setting up monitoring alerts..."
    
    # Create a simple monitoring script
    cat > "anf-health-monitor-daemon.sh" << 'EOF'
#!/bin/bash
# Simple monitoring daemon for Azure NetApp Files health

WEBHOOK_URL="$1"
CHECK_INTERVAL="${2:-300}" # 5 minutes default

while true; do
    # Check for active service issues
    ISSUES=$(az graph query --query 'ServiceHealthResources | where type =~ "Microsoft.ResourceHealth/events" | where properties.EventType == "ServiceIssue" and properties.Status == "Active" | count' --output json 2>/dev/null | jq -r '.data[0].count_')
    
    if [ "$ISSUES" -gt 0 ]; then
        MESSAGE="🚨 ALERT: $ISSUES active service issues detected for Azure services"
        curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL" 2>/dev/null || echo "Failed to send alert"
    fi
    
    # Check for unhealthy NetApp Files resources
    UNHEALTHY=$(az graph query --query 'HealthResources | where type =~ "microsoft.resourcehealth/availabilitystatuses" | where tostring(properties.targetResourceType) =~ "microsoft.netapp" and tostring(properties.availabilityState) != "Available" | count' --output json 2>/dev/null | jq -r '.data[0].count_')
    
    if [ "$UNHEALTHY" -gt 0 ]; then
        MESSAGE="⚠️ ALERT: $UNHEALTHY unhealthy Azure NetApp Files resources detected"
        curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$MESSAGE\"}" "$WEBHOOK_URL" 2>/dev/null || echo "Failed to send alert"
    fi
    
    sleep "$CHECK_INTERVAL"
done
EOF
    
    chmod +x "anf-health-monitor-daemon.sh"
    log "Monitoring daemon created: anf-health-monitor-daemon.sh"
    log "To start monitoring: ./anf-health-monitor-daemon.sh '$webhook_url' &"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --all                      Run all health checks"
    echo "  --service-events           Get active service health events"
    echo "  --health-advisories        Get active health advisories"
    echo "  --retirement-events        Get upcoming retirement events"
    echo "  --planned-maintenance      Get active planned maintenance"
    echo "  --service-issues           Get active service issues (outages)"
    echo "  --impacted-resources       Get confirmed impacted resources"
    echo "  --netapp-specific          Filter events for NetApp Files"
    echo "  --resource-health          Get NetApp Files resource health"
    echo "  --generate-report          Generate comprehensive health report"
    echo "  --setup-monitoring URL     Setup monitoring with webhook alerts"
    echo "  --help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --service-issues --netapp-specific"
    echo "  $0 --generate-report"
    echo "  $0 --setup-monitoring https://hooks.slack.com/your/webhook/url"
}

# Main function
main() {
    log "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    
    check_dependencies
    
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    local run_all=false
    local webhook_url=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                run_all=true
                shift
                ;;
            --service-events)
                get_active_service_health_events
                shift
                ;;
            --health-advisories)
                get_active_health_advisories
                shift
                ;;
            --retirement-events)
                get_upcoming_retirement_events
                shift
                ;;
            --planned-maintenance)
                get_active_planned_maintenance
                shift
                ;;
            --service-issues)
                get_active_service_issues
                shift
                ;;
            --impacted-resources)
                get_confirmed_impacted_resources
                get_impacted_resources_with_details
                shift
                ;;
            --netapp-specific)
                filter_netapp_files_events
                shift
                ;;
            --resource-health)
                get_netapp_files_resource_health
                shift
                ;;
            --generate-report)
                generate_health_report
                shift
                ;;
            --setup-monitoring)
                webhook_url="$2"
                setup_monitoring_alerts "$webhook_url"
                shift 2
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
    
    if [ "$run_all" = true ]; then
        get_active_service_health_events
        get_active_health_advisories
        get_upcoming_retirement_events
        get_active_planned_maintenance
        get_all_active_service_health
        get_active_service_issues
        get_confirmed_impacted_resources
        get_impacted_resources_with_details
        filter_netapp_files_events
        get_netapp_files_resource_health
        generate_health_report
    fi
    
    log "$SCRIPT_NAME completed successfully"
}

# Run main function with all arguments
main "$@"
