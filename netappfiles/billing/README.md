# Azure NetApp Files - Billing and Cost Management

This directory contains comprehensive Azure CLI scripts for managing Azure NetApp Files costs, billing analysis, and budget management.

## Scripts Overview

### 1. anf-cost-analysis.sh
Comprehensive cost analysis and optimization tool for Azure NetApp Files.

**Features:**
- Historical cost analysis for any date range
- Current resource cost estimation
- Cost optimization recommendations
- CSV export functionality
- Cost alert setup
- ANF pricing reference

**Usage Examples:**
```bash
# Analyze costs for January 2025
./anf-cost-analysis.sh -s 2025-01-01 -e 2025-01-31

# Analyze current resources and get recommendations
./anf-cost-analysis.sh -c

# Export cost data to CSV
./anf-cost-analysis.sh -x -s 2025-01-01 -e 2025-01-31

# Set up cost alerts with $1000 budget
./anf-cost-analysis.sh -r myResourceGroup -b 1000

# Show current ANF pricing
./anf-cost-analysis.sh -p
```

### 2. anf-budget-management.sh
Advanced budget creation, monitoring, and alert management for ANF resources.

**Features:**
- Create budgets with multiple threshold alerts (50%, 75%, 90%, 100%)
- Update existing budgets
- Delete budgets with confirmation
- Budget status monitoring
- Action group creation for alerts
- Comprehensive budget reporting

**Usage Examples:**
```bash
# Create monthly budget with email alerts
./anf-budget-management.sh create --name anf-monthly --amount 1000 --rg anf-rg --emails admin@company.com

# Update budget amount
./anf-budget-management.sh update --name anf-monthly --amount 1500

# Check status of specific budget
./anf-budget-management.sh status --name anf-monthly

# List all budgets
./anf-budget-management.sh list

# Generate budget report
./anf-budget-management.sh report

# Create action group for alerts
./anf-budget-management.sh create-alerts --name anf-alerts --rg anf-rg --emails admin@company.com,finance@company.com
```

## Cost Optimization Best Practices

### 1. Service Level Optimization
- **Standard**: Use for development, testing, and non-critical workloads
- **Premium**: Use for production workloads requiring moderate performance
- **Ultra**: Reserve for high-performance, latency-sensitive applications

### 2. Capacity Management
- Right-size capacity pools based on actual utilization
- Monitor pool utilization and resize when efficiency drops below 50%
- Use volume quotas to prevent over-consumption

### 3. Snapshot Management
- Implement automated snapshot policies with appropriate retention
- Clean up old snapshots regularly (use delete operations scripts)
- Consider snapshot frequency vs. recovery requirements

### 4. Replication Considerations
- Use cross-region replication only when necessary for DR
- Consider cross-zone replication for high availability within region
- Monitor replication bandwidth costs

### 5. Regular Monitoring
- Set up budget alerts at multiple thresholds (50%, 75%, 90%)
- Review cost reports monthly
- Use Azure Advisor recommendations for ANF

## Pricing Reference (East US - Subject to Change)

### Service Levels (per TiB/month)
- **Standard**: ~$146/TiB/month (~$0.000202/GiB/hour)
- **Premium**: ~$293/TiB/month (~$0.000403/GiB/hour)
- **Ultra**: ~$391/TiB/month (~$0.000538/GiB/hour)

### Additional Costs
- **Snapshots**: ~$0.05/GiB/month
- **Cross-region replication**: ~$0.10/GiB/month
- **Cross-zone replication**: ~$0.05/GiB/month

### Cost Calculation Examples

**Example 1: 1 TiB Premium Volume**
- Base cost: $293/month
- 100 GB snapshots: $5/month
- **Total**: ~$298/month

**Example 2: 10 TiB Standard Pool with 80% utilization**
- Pool cost: 10 × $146 = $1,460/month
- Actual usage cost: 8 × $146 = $1,168/month
- **Optimization**: Resize to 8 TiB to save $292/month

## Prerequisites

### Azure CLI Setup
```bash
# Install Azure CLI (if not already installed)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Install consumption extension (if needed)
az extension add --name consumption

# Set subscription context
az account set --subscription "your-subscription-id"
```

### Required Permissions
- **Cost Management Reader**: For cost analysis and consumption data
- **Cost Management Contributor**: For budget creation and management
- **NetApp Files Reader**: For ANF resource information
- **Monitoring Contributor**: For action group creation

## Advanced Features

### 1. Custom Budget Filters
The budget management script can create ANF-specific budgets with filters for:
- Resource groups containing ANF resources
- Service categories (Azure NetApp Files, Storage)
- Specific resource types

### 2. Automated Reporting
Set up scheduled runs using cron for automated reporting:
```bash
# Daily cost check at 8 AM
0 8 * * * /path/to/anf-cost-analysis.sh -c >> /var/log/anf-daily-costs.log

# Weekly budget report on Mondays at 9 AM
0 9 * * 1 /path/to/anf-budget-management.sh report
```

### 3. Integration with Azure Monitor
The scripts can be integrated with Azure Monitor for:
- Custom metrics and dashboards
- Automated alerts based on cost thresholds
- Integration with Azure Logic Apps for automated responses

## Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Check current permissions
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

2. **Consumption Data Not Available**
   - Cost data may have 24-48 hour delay
   - Ensure proper subscription access
   - Verify billing account permissions

3. **Budget Creation Failures**
   - Check resource group exists
   - Verify email addresses are valid
   - Ensure subscription has billing information

### Debug Mode
Run scripts with debugging:
```bash
# Enable verbose logging
set -x
./anf-cost-analysis.sh -c
set +x
```

## Support and Documentation

- [Azure NetApp Files Pricing](https://azure.microsoft.com/pricing/details/netapp/)
- [Azure Cost Management Documentation](https://docs.microsoft.com/en-us/azure/cost-management-billing/)
- [Azure NetApp Files Documentation](https://docs.microsoft.com/en-us/azure/azure-netapp-files/)

For issues or questions, refer to the main repository documentation or Azure support channels.
