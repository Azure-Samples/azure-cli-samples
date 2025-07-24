# Azure NetApp Files - Monitoring & Health Checks

This directory contains comprehensive monitoring and health check scripts for Azure NetApp Files resources.

## 📁 Directory Structure

```
monitoring/
├── service-health-comprehensive.sh     # Comprehensive Azure Service Health monitoring
├── advisor-recommendations-comprehensive.sh # Complete Azure Advisor integration
└── README.md                          # This file
```

## 🚀 Quick Start

### Service Health Monitoring

Monitor Azure Service Health for NetApp Files issues:

```bash
# Run all health checks
./service-health-comprehensive.sh --all

# Check for active service issues (outages)
./service-health-comprehensive.sh --service-issues

# Check NetApp Files specific events
./service-health-comprehensive.sh --netapp-specific

# Generate comprehensive health report
./service-health-comprehensive.sh --generate-report

# Setup monitoring with alerts
./service-health-comprehensive.sh --setup-monitoring https://hooks.slack.com/your/webhook/url
```

### Azure Advisor Recommendations

Get and manage Azure Advisor recommendations:

```bash
# List all recommendations
./advisor-recommendations-comprehensive.sh --list

# Get recommendations by category
./advisor-recommendations-comprehensive.sh --cost
./advisor-recommendations-comprehensive.sh --high-availability
./advisor-recommendations-comprehensive.sh --performance
./advisor-recommendations-comprehensive.sh --security

# Analyze NetApp Files specific recommendations
./advisor-recommendations-comprehensive.sh --netapp-analysis

# Generate fresh recommendations
./advisor-recommendations-comprehensive.sh --fresh

# Generate comprehensive report
./advisor-recommendations-comprehensive.sh --generate-report
```

## 📊 Features

### Service Health Monitoring

**Comprehensive Coverage:**
- ✅ Active service health events by subscription
- ✅ Health advisory events
- ✅ Service retirement events
- ✅ Planned maintenance events
- ✅ Service issue events (outages)
- ✅ Confirmed impacted resources
- ✅ NetApp Files specific filtering
- ✅ Resource health monitoring

**Azure Resource Graph Queries:**
- Uses all documented Azure Resource Graph queries for Service Health
- Filters for Azure NetApp Files specific events
- Provides detailed resource impact analysis

**Monitoring & Alerts:**
- Real-time monitoring daemon
- Webhook integration for alerts
- Comprehensive reporting

### Azure Advisor Recommendations

**Complete CLI Integration:**
- ✅ `az advisor recommendation list` - All filtering options
- ✅ `az advisor recommendation disable` - Dismiss recommendations
- ✅ `az advisor recommendation enable` - Re-enable recommendations
- ✅ Category filtering (Cost, HighAvailability, Performance, Security)
- ✅ Bulk operations for recommendation management

**NetApp Files Focus:**
- Automatic filtering for NetApp Files specific recommendations
- Impact analysis and prioritization
- Resource-specific recommendation grouping

**Advanced Features:**
- Bulk disable low priority recommendations
- Comprehensive reporting with JSON export
- Monitoring daemon for high-impact recommendations

## 🔍 Service Health Query Examples

The service health script implements all Azure Resource Graph queries from Microsoft documentation:

### Active Service Issues
```bash
# Get all active service issues affecting any Azure service
./service-health-comprehensive.sh --service-issues
```

### Health Advisories
```bash
# Get all active health advisory events
./service-health-comprehensive.sh --health-advisories
```

### Planned Maintenance
```bash
# Get all active planned maintenance events
./service-health-comprehensive.sh --planned-maintenance
```

### Resource Health
```bash
# Check resource health for NetApp Files resources
./service-health-comprehensive.sh --resource-health
```

### NetApp Files Specific
```bash
# Filter all events for NetApp Files service specifically
./service-health-comprehensive.sh --netapp-specific
```

## 💡 Advisor Recommendation Examples

### List Recommendations
```bash
# List all recommendations
./advisor-recommendations-comprehensive.sh --list

# List recommendations with fresh generation
./advisor-recommendations-comprehensive.sh --list --refresh

# List recommendations for specific resource group
./advisor-recommendations-comprehensive.sh --list --resource-group myResourceGroup

# List recommendations by category
./advisor-recommendations-comprehensive.sh --list --category Cost
```

### Manage Recommendations
```bash
# Disable a recommendation for 30 days
./advisor-recommendations-comprehensive.sh --disable "MyRecommendationName" --days 30

# Disable a recommendation permanently
./advisor-recommendations-comprehensive.sh --disable "MyRecommendationName"

# Enable a previously disabled recommendation
./advisor-recommendations-comprehensive.sh --enable "MyRecommendationName"

# Bulk disable all low priority recommendations for 7 days
./advisor-recommendations-comprehensive.sh --bulk-disable-low --days 7
```

### NetApp Files Analysis
```bash
# Analyze recommendations specifically for NetApp Files resources
./advisor-recommendations-comprehensive.sh --netapp-analysis
```

## 🚨 Monitoring & Alerting

### Service Health Monitoring
```bash
# Setup monitoring with Slack webhook
./service-health-comprehensive.sh --setup-monitoring https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK

# Start the monitoring daemon (runs in background)
./anf-health-monitor-daemon.sh https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK &
```

### Advisor Monitoring
```bash
# Setup advisor monitoring with custom threshold
./advisor-recommendations-comprehensive.sh --setup-monitoring https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK --threshold 5

# Start the advisor monitoring daemon
./anf-advisor-monitor-daemon.sh https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK 5 &
```

## 📈 Integration with Main Automation

These monitoring scripts are automatically integrated with the main ANF automation system:

```bash
# Run complete automation including monitoring setup
python run_complete_anf_automation.py

# Run comprehensive job runner (includes monitoring)
python anf_comprehensive_job_runner.py
```

## 🔧 Dependencies

- Azure CLI (`az`)
- jq (JSON processor)
- curl (for webhook alerts)
- Bash 4.0+

## 📝 Output & Reports

### Service Health Reports
- JSON format with comprehensive event details
- Resource impact analysis
- Historical trend data
- Alert summaries

### Advisor Reports
- Categorized recommendation analysis
- NetApp Files specific filtering
- Impact prioritization
- Action recommendations

## 🆘 Troubleshooting

### Common Issues

1. **Azure CLI Authentication**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Missing jq**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # RHEL/CentOS
   sudo yum install jq
   
   # macOS
   brew install jq
   ```

3. **Permission Issues**
   ```bash
   chmod +x *.sh
   ```

### Debug Mode

Enable debug output by setting:
```bash
export ANF_DEBUG=1
./service-health-comprehensive.sh --all
```

## 🔗 Related Resources

- [Azure Service Health Documentation](https://docs.microsoft.com/en-us/azure/service-health/)
- [Azure Advisor Documentation](https://docs.microsoft.com/en-us/azure/advisor/)
- [Azure Resource Graph Queries](https://docs.microsoft.com/en-us/azure/governance/resource-graph/samples/)
- [Azure NetApp Files Documentation](https://docs.microsoft.com/en-us/azure/azure-netapp-files/)

---

**Note:** This monitoring system provides comprehensive coverage of Azure Service Health and Advisor functionality with specific focus on Azure NetApp Files resources. All Azure CLI commands and Resource Graph queries documented by Microsoft are implemented and integrated.
