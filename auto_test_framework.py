#!/usr/bin/env python3
"""
Azure CLI Samples Auto-Test Framework
====================================

Comprehensive testing system that validates scripts before auto-PR submission.
Integrates with confidence scoring and cluster job system.

Features:
- Pre-PR validation testing
- Azure CLI samples compliance checking
- Functional testing with mock Azure CLI
- Confidence scoring integration
- Automated testing for all script categories
- Retroactive testing for existing scripts
"""

import os
import json
import subprocess
import tempfile
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class TestResult:
    """Test result data structure."""
    script_path: str
    syntax_valid: bool
    compliance_score: float
    functional_score: float
    overall_confidence: float
    passed_tests: List[str]
    failed_tests: List[str]
    warnings: List[str]
    execution_time: float
    ready_for_pr: bool

class AzureCLIScriptTester:
    """Comprehensive Azure CLI script testing framework."""
    
    def __init__(self, workspace_path: Path):
        self.workspace_path = workspace_path
        self.test_results = {}
        
        # Testing thresholds
        self.confidence_thresholds = {
            "syntax_minimum": 90.0,
            "compliance_minimum": 85.0,
            "functional_minimum": 80.0,
            "auto_pr_threshold": 92.0,
            "manual_review_threshold": 85.0
        }
        
        # Azure CLI samples requirements
        self.compliance_requirements = [
            "bash_shell",
            "test_date",
            "test_method", 
            "random_resources",
            "no_hardcoded_secrets",
            "environment_variables",
            "non_interactive",
            "azure_cli_version",
            "proper_parameters"
        ]
        
        # Script categories for testing
        self.script_categories = [
            "troubleshooting",
            "provisioning", 
            "monitoring",
            "operations",
            "solution-architectures",
            "billing",
            "read",
            "update",
            "delete"
        ]

    def create_mock_azure_cli(self, temp_dir: str) -> str:
        """Create mock Azure CLI for functional testing."""
        mock_script = '''#!/bin/bash
# Mock Azure CLI for comprehensive testing

case "$*" in
    "account show --query id -o tsv")
        echo "12345678-1234-1234-1234-123456789012"
        ;;
    *"netappfiles account"*)
        case "$*" in
            *"ad list"*)
                cat << 'EOF'
[
  {
    "activeDirectoryId": "test-ad-connection",
    "domain": "contoso.com", 
    "dns": "10.0.0.4,10.0.0.5",
    "username": "admin@contoso.com",
    "smbServerName": "anf-smb-server",
    "organizationalUnit": "OU=ANF,DC=contoso,DC=com",
    "aesEncryption": true,
    "ldapSigning": true,
    "ldapOverTLS": true,
    "allowLocalNfsUsersWithLdap": false
  }
]
EOF
                ;;
            *"show"*)
                cat << 'EOF'
{
  "name": "test-account",
  "location": "eastus",
  "activeDirectories": ["test-ad-connection"]
}
EOF
                ;;
            *"create"*)
                echo '{"id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.NetApp/netAppAccounts/test-account"}'
                ;;
        esac
        ;;
    *"netappfiles pool"*)
        case "$*" in
            *"show"*)
                cat << 'EOF'
{
  "name": "test-pool",
  "size": 4398046511104,
  "serviceLevel": "Premium"
}
EOF
                ;;
            *"create"*)
                echo '{"id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.NetApp/netAppAccounts/test-account/capacityPools/test-pool"}'
                ;;
        esac
        ;;
    *"netappfiles volume"*)
        case "$*" in
            *"show"*)
                cat << 'EOF'
{
  "name": "test-volume",
  "protocolTypes": ["NFSv4.1", "CIFS"],
  "kerberosEnabled": true,
  "smbEncryption": true,
  "smbAccessBasedEnumeration": false,
  "smbNonBrowsable": false,
  "unixPermissions": "0755",
  "hasRootAccess": true,
  "exportPolicy": {
    "rules": [
      {
        "allowedClients": "0.0.0.0/0",
        "nfsv3": false,
        "nfsv41": true,
        "kerberos5ReadOnly": true,
        "kerberos5ReadWrite": true
      }
    ]
  }
}
EOF
                ;;
            *"create"*)
                echo '{"id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.NetApp/netAppAccounts/test-account/capacityPools/test-pool/volumes/test-volume"}'
                ;;
        esac
        ;;
    *"advisor recommendation"*)
        cat << 'EOF'
[
  {
    "id": "advisor-rec-1",
    "type": "Microsoft.Advisor/recommendations",
    "category": "Performance",
    "impact": "Medium",
    "shortDescription": {"solution": "Optimize NetApp Files performance"}
  }
]
EOF
        ;;
    *"resource list"*)
        cat << 'EOF'
[
  {
    "id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.NetApp/netAppAccounts/test-account",
    "name": "test-account",
    "type": "Microsoft.NetApp/netAppAccounts",
    "location": "eastus"
  }
]
EOF
        ;;
    "--version")
        echo "azure-cli 2.56.0"
        echo "core 2.56.0"
        echo "telemetry 1.1.0"
        ;;
    *)
        echo "Mock Azure CLI - Command: $*" >&2
        exit 0
        ;;
esac
'''
        
        mock_az_path = os.path.join(temp_dir, "az")
        with open(mock_az_path, 'w') as f:
            f.write(mock_script)
        
        # Make executable
        try:
            os.chmod(mock_az_path, 0o755)
        except:
            pass  # Windows doesn't need chmod
            
        return mock_az_path

    def test_script_syntax(self, script_path: Path) -> Tuple[bool, List[str]]:
        """Test bash script syntax."""
        issues = []
        
        try:
            # Read script content
            with open(script_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Check shebang
            if not content.startswith('#!/bin/bash'):
                issues.append("Missing or incorrect shebang (should be #!/bin/bash)")
            
            # Test syntax with bash if available
            try:
                result = subprocess.run(
                    ['bash', '-n', str(script_path)],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                if result.returncode != 0:
                    issues.append(f"Bash syntax errors: {result.stderr}")
            except FileNotFoundError:
                issues.append("Bash not available for syntax validation")
            except subprocess.TimeoutExpired:
                issues.append("Syntax check timed out")
            
            return len(issues) == 0, issues
            
        except Exception as e:
            issues.append(f"Error reading script: {e}")
            return False, issues

    def test_azure_cli_compliance(self, script_path: Path) -> Tuple[float, List[str], List[str]]:
        """Test Azure CLI samples compliance."""
        passed = []
        failed = []
        
        try:
            with open(script_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Test each requirement
            tests = [
                ("bash_shell", content.startswith('#!/bin/bash'), "Uses bash shell"),
                ("test_date", 'Last tested:' in content, "Contains test date"),
                ("test_method", 'Test method:' in content, "Contains test method"),
                ("random_resources", 'randomSuffix' in content and ('$RANDOM' in content or 'shuf' in content), "Uses random resource naming"),
                ("no_hardcoded_secrets", 'your-password' not in content or content.count('password') <= 2, "No hardcoded secrets"),
                ("environment_variables", ':-' in content, "Supports environment variables"),
                ("non_interactive", 'read -p' not in content, "Non-interactive execution"),
                ("azure_cli_version", 'Azure CLI version' in content, "Specifies Azure CLI version"),
                ("proper_parameters", '--resource-group' in content and '--query' in content, "Uses proper Azure CLI parameters")
            ]
            
            for test_id, condition, description in tests:
                if condition:
                    passed.append(f"{test_id}: {description}")
                else:
                    failed.append(f"{test_id}: {description}")
            
            # Calculate compliance score
            compliance_score = (len(passed) / len(tests)) * 100
            
            return compliance_score, passed, failed
            
        except Exception as e:
            failed.append(f"Error reading script: {e}")
            return 0.0, passed, failed

    def test_script_functionality(self, script_path: Path) -> Tuple[float, List[str], List[str]]:
        """Test script functionality with mock Azure CLI."""
        passed = []
        failed = []
        
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                # Create mock Azure CLI
                mock_az_path = self.create_mock_azure_cli(temp_dir)
                
                # Prepare environment
                env = os.environ.copy()
                env['PATH'] = temp_dir + os.pathsep + env.get('PATH', '')
                env['ANF_RESOURCE_GROUP'] = 'test-rg-1234'
                env['ANF_ACCOUNT'] = 'test-account-1234'
                env['ANF_VOLUME'] = 'test-volume-1234'
                env['ANF_POOL'] = 'test-pool-1234'
                
                # Execute script with timeout
                try:
                    result = subprocess.run(
                        ['bash', str(script_path)],
                        capture_output=True,
                        text=True,
                        env=env,
                        timeout=45,
                        cwd=script_path.parent
                    )
                    
                    output = result.stdout
                    
                    # Analyze output for expected functionality
                    functionality_checks = [
                        ("subscription_detection", "subscription" in output.lower(), "Subscription detection"),
                        ("azure_cli_usage", len([line for line in output.split('\n') if 'az ' in line]) > 0, "Azure CLI command usage"),
                        ("error_handling", result.returncode in [0, 1], "Proper error handling"),
                        ("informative_output", len(output) > 100, "Provides informative output"),
                        ("no_crashes", "Traceback" not in result.stderr, "No unexpected crashes")
                    ]
                    
                    # Add category-specific checks
                    if "troubleshoot" in str(script_path):
                        functionality_checks.extend([
                            ("troubleshooting_sections", "Testing" in output or "Checking" in output, "Contains troubleshooting sections"),
                            ("recommendations", "Recommendation" in output or "Solution" in output, "Provides recommendations")
                        ])
                    elif "provision" in str(script_path):
                        functionality_checks.extend([
                            ("resource_creation", "create" in output.lower(), "Resource creation logic"),
                            ("configuration", "configur" in output.lower(), "Configuration steps")
                        ])
                    elif "monitor" in str(script_path):
                        functionality_checks.extend([
                            ("monitoring_data", "monitor" in output.lower() or "metric" in output.lower(), "Monitoring functionality"),
                            ("health_checks", "health" in output.lower() or "status" in output.lower(), "Health checking")
                        ])
                    
                    # Evaluate checks
                    for check_id, condition, description in functionality_checks:
                        if condition:
                            passed.append(f"{check_id}: {description}")
                        else:
                            failed.append(f"{check_id}: {description}")
                    
                    # Calculate functional score
                    functional_score = (len(passed) / len(functionality_checks)) * 100
                    
                    return functional_score, passed, failed
                    
                except subprocess.TimeoutExpired:
                    failed.append("Script execution timed out (45s)")
                    return 0.0, passed, failed
                    
        except Exception as e:
            failed.append(f"Functional test error: {e}")
            return 0.0, passed, failed

    def calculate_confidence_score(self, syntax_valid: bool, compliance_score: float, functional_score: float) -> float:
        """Calculate overall confidence score."""
        if not syntax_valid:
            return 0.0
        
        # Weighted scoring
        weights = {
            "syntax": 0.2,      # 20% - Must pass
            "compliance": 0.4,   # 40% - Critical for Azure CLI samples
            "functional": 0.4    # 40% - Script must work
        }
        
        syntax_score = 100.0 if syntax_valid else 0.0
        
        confidence = (
            syntax_score * weights["syntax"] +
            compliance_score * weights["compliance"] +
            functional_score * weights["functional"]
        )
        
        return min(confidence, 100.0)

    def test_single_script(self, script_path: Path) -> TestResult:
        """Test a single script comprehensively."""
        start_time = datetime.now()
        
        logger.info(f"Testing script: {script_path}")
        
        # Syntax testing
        syntax_valid, syntax_issues = self.test_script_syntax(script_path)
        
        # Compliance testing
        compliance_score, compliance_passed, compliance_failed = self.test_azure_cli_compliance(script_path)
        
        # Functional testing
        functional_score, functional_passed, functional_failed = self.test_script_functionality(script_path)
        
        # Calculate overall confidence
        confidence = self.calculate_confidence_score(syntax_valid, compliance_score, functional_score)
        
        # Determine if ready for PR
        ready_for_pr = (
            syntax_valid and
            compliance_score >= self.confidence_thresholds["compliance_minimum"] and
            functional_score >= self.confidence_thresholds["functional_minimum"] and
            confidence >= self.confidence_thresholds["auto_pr_threshold"]
        )
        
        # Collect all results
        all_passed = compliance_passed + functional_passed
        all_failed = syntax_issues + compliance_failed + functional_failed
        
        execution_time = (datetime.now() - start_time).total_seconds()
        
        return TestResult(
            script_path=str(script_path),
            syntax_valid=syntax_valid,
            compliance_score=compliance_score,
            functional_score=functional_score,
            overall_confidence=confidence,
            passed_tests=all_passed,
            failed_tests=all_failed,
            warnings=[],
            execution_time=execution_time,
            ready_for_pr=ready_for_pr
        )

    def discover_scripts(self) -> List[Path]:
        """Discover all bash scripts in the Azure CLI samples structure."""
        scripts = []
        
        # Look for bash scripts in netappfiles directory
        netappfiles_dir = self.workspace_path / "netappfiles"
        if netappfiles_dir.exists():
            for script_file in netappfiles_dir.rglob("*.sh"):
                if script_file.is_file():
                    scripts.append(script_file)
        
        return scripts

    def test_all_scripts(self) -> Dict[str, TestResult]:
        """Test all discovered scripts."""
        scripts = self.discover_scripts()
        results = {}
        
        logger.info(f"Discovered {len(scripts)} scripts for testing")
        
        for script_path in scripts:
            try:
                result = self.test_single_script(script_path)
                results[str(script_path)] = result
                
                # Log result
                status = "✅ READY" if result.ready_for_pr else "⚠️ NEEDS WORK"
                logger.info(f"{status} {script_path.name} - Confidence: {result.overall_confidence:.1f}%")
                
            except Exception as e:
                logger.error(f"Error testing {script_path}: {e}")
                
        return results

    def generate_test_report(self, results: Dict[str, TestResult]) -> str:
        """Generate comprehensive test report."""
        ready_count = sum(1 for r in results.values() if r.ready_for_pr)
        total_count = len(results)
        
        report = f"""
# Azure CLI Samples Auto-Test Report
Generated: {datetime.now().isoformat()}

## Summary
- **Total Scripts**: {total_count}
- **Ready for Auto-PR**: {ready_count}
- **Need Manual Review**: {total_count - ready_count}
- **Success Rate**: {(ready_count/total_count*100):.1f}%

## Test Results by Script

"""
        
        # Sort by confidence score (highest first)
        sorted_results = sorted(results.items(), key=lambda x: x[1].overall_confidence, reverse=True)
        
        for script_path, result in sorted_results:
            script_name = Path(script_path).name
            status = "🚀 AUTO-PR READY" if result.ready_for_pr else "📝 MANUAL REVIEW"
            
            report += f"""
### {script_name}
- **Status**: {status}
- **Overall Confidence**: {result.overall_confidence:.1f}%
- **Compliance Score**: {result.compliance_score:.1f}%
- **Functional Score**: {result.functional_score:.1f}%
- **Syntax Valid**: {'✅' if result.syntax_valid else '❌'}
- **Execution Time**: {result.execution_time:.2f}s

"""
            
            if result.failed_tests:
                report += "**Issues to Address:**\n"
                for issue in result.failed_tests[:5]:  # Show top 5 issues
                    report += f"- {issue}\n"
                if len(result.failed_tests) > 5:
                    report += f"- ... and {len(result.failed_tests) - 5} more\n"
                report += "\n"
        
        # Add recommendations
        report += f"""
## Recommendations

### Ready for Auto-PR ({ready_count} scripts)
These scripts meet all quality thresholds and can be automatically submitted:
"""
        
        for script_path, result in sorted_results:
            if result.ready_for_pr:
                report += f"- {Path(script_path).name} ({result.overall_confidence:.1f}%)\n"
        
        report += f"""
### Need Manual Review ({total_count - ready_count} scripts)
These scripts need attention before auto-PR submission:
"""
        
        for script_path, result in sorted_results:
            if not result.ready_for_pr:
                report += f"- {Path(script_path).name} ({result.overall_confidence:.1f}%) - "
                if not result.syntax_valid:
                    report += "Syntax issues"
                elif result.compliance_score < self.confidence_thresholds["compliance_minimum"]:
                    report += "Compliance issues"
                elif result.functional_score < self.confidence_thresholds["functional_minimum"]:
                    report += "Functional issues"
                else:
                    report += "Overall confidence below threshold"
                report += "\n"
        
        return report

def main():
    """Main testing function."""
    workspace_path = Path(__file__).parent
    tester = AzureCLIScriptTester(workspace_path)
    
    print("🧪 Azure CLI Samples Auto-Test Framework")
    print("="*50)
    print(f"Workspace: {workspace_path}")
    print(f"Auto-PR Threshold: {tester.confidence_thresholds['auto_pr_threshold']}%")
    
    # Test all scripts
    results = tester.test_all_scripts()
    
    # Generate report
    report = tester.generate_test_report(results)
    
    # Save report
    report_path = workspace_path / "auto_test_report.md"
    with open(report_path, 'w') as f:
        f.write(report)
    
    print(f"\n📋 Test report saved: {report_path}")
    
    # Summary
    ready_count = sum(1 for r in results.values() if r.ready_for_pr)
    total_count = len(results)
    
    print(f"\n📊 Final Summary:")
    print(f"   Total Scripts: {total_count}")
    print(f"   Ready for Auto-PR: {ready_count}")
    print(f"   Need Review: {total_count - ready_count}")
    print(f"   Success Rate: {(ready_count/total_count*100):.1f}%")
    
    if ready_count > 0:
        print(f"\n🚀 {ready_count} scripts are ready for automatic PR submission!")
    
    return results

if __name__ == "__main__":
    main()
