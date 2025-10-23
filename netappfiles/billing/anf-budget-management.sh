#!/bin/bash
# Azure NetApp Files Budget Management and Cost Controls
# Automated budget creation, monitoring, and alert management

set -e

# Configuration
SCRIPT_NAME="ANF Budget Management"
LOG_FILE="anf-budget-management-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check prerequisites
check_prerequisites() {
    if ! az account show &>/dev/null; then
        error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    # Check if consumption extension is available
    if ! az extension list --query "[?name=='consumption']" -o tsv | grep -q consumption; then
        warn "Azure CLI consumption extension not found. Installing..."
        az extension add --name consumption
    fi
    
    log "Prerequisites verified"
}

# Function to create comprehensive ANF budget
create_anf_budget() {
    local budget_name="$1"
    local amount="$2"
    local resource_group="$3"
    local email_contacts="$4"
    local time_grain="${5:-Monthly}"
    
    if [ -z "$budget_name" ] || [ -z "$amount" ] || [ -z "$resource_group" ]; then
        error "Budget name, amount, and resource group are required"
        return 1
    fi
    
    if [ -z "$email_contacts" ]; then
        email_contacts='["admin@company.com"]'
    fi
    
    log "Creating ANF budget: $budget_name with amount: \$$amount"
    
    # Create budget with multiple threshold notifications
    local notifications='[
        {"enabled":true,"operator":"GreaterThan","threshold":50,"contactEmails":'$email_contacts',"thresholdType":"Actual","locale":"en-us"},
        {"enabled":true,"operator":"GreaterThan","threshold":75,"contactEmails":'$email_contacts',"thresholdType":"Actual","locale":"en-us"},
        {"enabled":true,"operator":"GreaterThan","threshold":90,"contactEmails":'$email_contacts',"thresholdType":"Actual","locale":"en-us"},
        {"enabled":true,"operator":"GreaterThan","threshold":100,"contactEmails":'$email_contacts',"thresholdType":"Actual","locale":"en-us"},
        {"enabled":true,"operator":"GreaterThan","threshold":80,"contactEmails":'$email_contacts',"thresholdType":"Forecasted","locale":"en-us"}
    ]'
    
    local start_date=$(date +%Y-%m-01)
    local end_date=$(date -d '+1 year' +%Y-%m-01)
    
    # Create the budget
    if az consumption budget create \
        --budget-name "$budget_name" \
        --amount "$amount" \
        --resource-group "$resource_group" \
        --time-grain "$time_grain" \
        --start-date "$start_date" \
        --end-date "$end_date" \
        --notifications "$notifications" \
        --category "Cost" \
        --time-period-start "$start_date" \
        --time-period-end "$end_date"; then
        log "Budget '$budget_name' created successfully"
    else
        error "Failed to create budget '$budget_name'"
        return 1
    fi
}

# Function to create ANF-specific budget filters
create_anf_filtered_budget() {
    local budget_name="$1"
    local amount="$2"
    local subscription_id="$3"
    local email_contacts="$4"
    
    log "Creating ANF-specific filtered budget: $budget_name"
    
    # Create budget JSON configuration for ANF resources only
    local budget_config=$(cat <<EOF
{
    "name": "$budget_name",
    "properties": {
        "category": "Cost",
        "amount": $amount,
        "timeGrain": "Monthly",
        "timePeriod": {
            "startDate": "$(date +%Y-%m-01)",
            "endDate": "$(date -d '+1 year' +%Y-%m-01)"
        },
        "filter": {
            "and": [
                {
                    "dimensions": {
                        "name": "ResourceGroup",
                        "operator": "In",
                        "values": ["anf-rg", "netapp-rg"]
                    }
                },
                {
                    "or": [
                        {
                            "dimensions": {
                                "name": "ServiceName",
                                "operator": "In",
                                "values": ["Azure NetApp Files"]
                            }
                        },
                        {
                            "dimensions": {
                                "name": "MeterCategory",
                                "operator": "In",
                                "values": ["Storage"]
                            }
                        }
                    ]
                }
            ]
        },
        "notifications": {
            "Actual_50": {
                "enabled": true,
                "operator": "GreaterThan",
                "threshold": 50,
                "contactEmails": $email_contacts,
                "thresholdType": "Actual"
            },
            "Actual_75": {
                "enabled": true,
                "operator": "GreaterThan",
                "threshold": 75,
                "contactEmails": $email_contacts,
                "thresholdType": "Actual"
            },
            "Actual_90": {
                "enabled": true,
                "operator": "GreaterThan",
                "threshold": 90,
                "contactEmails": $email_contacts,
                "thresholdType": "Actual"
            },
            "Forecasted_80": {
                "enabled": true,
                "operator": "GreaterThan",
                "threshold": 80,
                "contactEmails": $email_contacts,
                "thresholdType": "Forecasted"
            }
        }
    }
}
EOF
)
    
    # Save configuration to temp file
    local temp_file="/tmp/anf-budget-config.json"
    echo "$budget_config" > "$temp_file"
    
    # Create budget using REST API call through Azure CLI
    az rest --method PUT \
        --uri "https://management.azure.com/subscriptions/$subscription_id/providers/Microsoft.Consumption/budgets/$budget_name?api-version=2021-10-01" \
        --body @"$temp_file"
    
    rm "$temp_file"
    log "ANF-filtered budget '$budget_name' created successfully"
}

# Function to list existing budgets
list_budgets() {
    log "Listing existing budgets..."
    
    az consumption budget list --query "[].{Name:name,Amount:amount,TimeGrain:timeGrain,Category:category,CurrentSpend:currentSpend.amount,ForecastedSpend:forecastedSpend}" --output table
}

# Function to update budget
update_budget() {
    local budget_name="$1"
    local new_amount="$2"
    
    if [ -z "$budget_name" ] || [ -z "$new_amount" ]; then
        error "Budget name and new amount are required"
        return 1
    fi
    
    log "Updating budget '$budget_name' to \$$new_amount"
    
    az consumption budget update \
        --budget-name "$budget_name" \
        --amount "$new_amount"
    
    log "Budget '$budget_name' updated successfully"
}

# Function to delete budget
delete_budget() {
    local budget_name="$1"
    
    if [ -z "$budget_name" ]; then
        error "Budget name is required"
        return 1
    fi
    
    warn "Deleting budget: $budget_name"
    read -p "Are you sure you want to delete budget '$budget_name'? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        az consumption budget delete --budget-name "$budget_name"
        log "Budget '$budget_name' deleted successfully"
    else
        info "Budget deletion cancelled"
    fi
}

# Function to check budget status
check_budget_status() {
    local budget_name="$1"
    
    if [ -z "$budget_name" ]; then
        log "Checking status of all budgets..."
        az consumption budget list --query "[].{Name:name,Amount:amount,CurrentSpend:currentSpend.amount,Percentage:round(currentSpend.amount/amount*100),Status:currentSpend.amount>amount && 'OVER BUDGET' || 'OK'}" --output table
    else
        log "Checking status of budget: $budget_name"
        az consumption budget show --budget-name "$budget_name" --query "{Name:name,Amount:amount,CurrentSpend:currentSpend.amount,ForecastedSpend:forecastedSpend,Notifications:notifications}" --output json
    fi
}

# Function to create spending alerts action group
create_alert_action_group() {
    local action_group_name="$1"
    local resource_group="$2"
    local email_addresses="$3"
    
    if [ -z "$action_group_name" ] || [ -z "$resource_group" ]; then
        error "Action group name and resource group are required"
        return 1
    fi
    
    log "Creating action group: $action_group_name"
    
    # Parse email addresses into Azure CLI format
    local email_receivers=""
    IFS=',' read -ra EMAILS <<< "$email_addresses"
    for i in "${!EMAILS[@]}"; do
        email_receivers="$email_receivers email receiver${i} ${EMAILS[$i]}"
    done
    
    az monitor action-group create \
        --name "$action_group_name" \
        --resource-group "$resource_group" \
        --action $email_receivers
    
    log "Action group '$action_group_name' created successfully"
}

# Function to generate budget report
generate_budget_report() {
    local output_file="anf-budget-report-$(date +%Y%m%d).md"
    
    log "Generating budget report: $output_file"
    
    cat > "$output_file" <<EOF
# Azure NetApp Files Budget Report
Generated on: $(date)

## Budget Summary
EOF
    
    # Add budget details to report
    az consumption budget list --query "[].{Name:name,Amount:amount,CurrentSpend:currentSpend.amount,Percentage:round(currentSpend.amount/amount*100)}" --output table >> "$output_file"
    
    cat >> "$output_file" <<EOF

## Budget Status
- Budgets Over 75%: $(az consumption budget list --query "length([?currentSpend.amount/amount > 0.75])" --output tsv)
- Budgets Over Budget: $(az consumption budget list --query "length([?currentSpend.amount > amount])" --output tsv)

## Recommendations
- Review budgets that are over 75% utilization
- Consider increasing budgets that consistently exceed limits
- Monitor forecasted spending for proactive management

## Next Steps
1. Review high-utilization budgets
2. Analyze spending patterns
3. Adjust budgets or resources as needed
4. Schedule regular budget reviews
EOF
    
    log "Budget report generated: $output_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Budget Management Options:"
    echo "  create --name NAME --amount AMOUNT --rg RG [--emails EMAILS]"
    echo "  update --name NAME --amount AMOUNT"
    echo "  delete --name NAME"
    echo "  list                          List all budgets"
    echo "  status [--name NAME]          Check budget status"
    echo "  report                        Generate budget report"
    echo ""
    echo "Alert Management Options:"
    echo "  create-alerts --name NAME --rg RG --emails EMAILS"
    echo ""
    echo "Examples:"
    echo "  $0 create --name anf-monthly --amount 1000 --rg anf-rg --emails admin@company.com"
    echo "  $0 update --name anf-monthly --amount 1500"
    echo "  $0 status --name anf-monthly"
    echo "  $0 list"
    echo "  $0 report"
}

# Main function
main() {
    log "Starting $SCRIPT_NAME"
    
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    check_prerequisites
    
    local action="$1"
    shift
    
    case "$action" in
        create)
            local budget_name=""
            local amount=""
            local resource_group=""
            local emails='["admin@company.com"]'
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --name)
                        budget_name="$2"
                        shift 2
                        ;;
                    --amount)
                        amount="$2"
                        shift 2
                        ;;
                    --rg)
                        resource_group="$2"
                        shift 2
                        ;;
                    --emails)
                        emails="[\"$(echo $2 | sed 's/,/","/g')\"]"
                        shift 2
                        ;;
                    *)
                        error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done
            
            create_anf_budget "$budget_name" "$amount" "$resource_group" "$emails"
            ;;
        update)
            local budget_name=""
            local amount=""
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --name)
                        budget_name="$2"
                        shift 2
                        ;;
                    --amount)
                        amount="$2"
                        shift 2
                        ;;
                    *)
                        error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done
            
            update_budget "$budget_name" "$amount"
            ;;
        delete)
            local budget_name=""
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --name)
                        budget_name="$2"
                        shift 2
                        ;;
                    *)
                        error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done
            
            delete_budget "$budget_name"
            ;;
        list)
            list_budgets
            ;;
        status)
            local budget_name=""
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --name)
                        budget_name="$2"
                        shift 2
                        ;;
                    *)
                        error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done
            
            check_budget_status "$budget_name"
            ;;
        report)
            generate_budget_report
            ;;
        create-alerts)
            local action_group_name=""
            local resource_group=""
            local emails=""
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --name)
                        action_group_name="$2"
                        shift 2
                        ;;
                    --rg)
                        resource_group="$2"
                        shift 2
                        ;;
                    --emails)
                        emails="$2"
                        shift 2
                        ;;
                    *)
                        error "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done
            
            create_alert_action_group "$action_group_name" "$resource_group" "$emails"
            ;;
        *)
            error "Unknown action: $action"
            show_usage
            exit 1
            ;;
    esac
    
    log "$SCRIPT_NAME completed successfully"
}

# Run main function with all arguments
main "$@"
