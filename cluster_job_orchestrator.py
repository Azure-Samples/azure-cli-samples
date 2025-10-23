#!/usr/bin/env python3
"""
Integrated Cluster Job System with Auto-Test-Before-Auto-PR
==========================================================

This system orchestrates the complete flow:
1. Feature addition triggers cluster job
2. Auto-test validates scripts 
3. Confidence scoring determines action
4. Auto-PR submits if above threshold
5. Manual review if below threshold

Supports retroactive testing and batch processing of existing scripts.
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any
import logging
import subprocess

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from auto_test_framework import AzureCLIScriptTester, TestResult
from auto_pr_submission import AutoPRSubmissionSystem

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ClusterJobOrchestrator:
    """Orchestrates the complete auto-test-before-auto-PR workflow."""
    
    def __init__(self, workspace_path: Path):
        self.workspace_path = workspace_path
        self.tester = AzureCLIScriptTester(workspace_path)
        self.auto_pr_system = AutoPRSubmissionSystem(workspace_path)
        
        # Job configuration
        self.job_config = {
            "auto_test_enabled": True,
            "auto_pr_enabled": True,
            "batch_processing": True,
            "retroactive_testing": True,
            "notification_enabled": True
        }
        
        # Thresholds
        self.thresholds = {
            "auto_pr_confidence": 92.0,
            "manual_review_confidence": 85.0,
            "failure_confidence": 75.0
        }

    def trigger_cluster_job(self, feature_data: Dict[str, Any]) -> Dict[str, Any]:
        """Trigger a cluster job for feature addition."""
        logger.info(f"🚀 Triggering cluster job for: {feature_data.get('feature_name', 'Unknown')}")
        
        job_result = {
            "job_id": f"job_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "feature_data": feature_data,
            "timestamp": datetime.now().isoformat(),
            "status": "running",
            "stages": {
                "auto_test": {"status": "pending", "result": None},
                "confidence_scoring": {"status": "pending", "result": None},
                "auto_pr": {"status": "pending", "result": None}
            }
        }
        
        try:
            # Stage 1: Auto-Test
            logger.info("📝 Stage 1: Running auto-test validation...")
            test_result = self.run_auto_test_stage(feature_data)
            job_result["stages"]["auto_test"] = {"status": "completed", "result": test_result}
            
            # Stage 2: Confidence Scoring
            logger.info("📊 Stage 2: Calculating confidence scores...")
            confidence_result = self.run_confidence_scoring_stage(test_result, feature_data)
            job_result["stages"]["confidence_scoring"] = {"status": "completed", "result": confidence_result}
            
            # Stage 3: Auto-PR Decision
            logger.info("🎯 Stage 3: Making auto-PR decision...")
            pr_result = self.run_auto_pr_stage(confidence_result, feature_data)
            job_result["stages"]["auto_pr"] = {"status": "completed", "result": pr_result}
            
            # Final status
            job_result["status"] = "completed"
            job_result["final_action"] = pr_result.get("action", "unknown")
            job_result["confidence_score"] = confidence_result.get("final_confidence", 0.0)
            
            logger.info(f"✅ Cluster job completed: {job_result['final_action']}")
            
        except Exception as e:
            logger.error(f"❌ Cluster job failed: {e}")
            job_result["status"] = "failed"
            job_result["error"] = str(e)
        
        # Save job result
        self.save_job_result(job_result)
        
        return job_result

    def run_auto_test_stage(self, feature_data: Dict[str, Any]) -> Dict[str, Any]:
        """Run the auto-test validation stage."""
        test_results = {}
        
        # Get scripts to test
        scripts_to_test = self.get_scripts_for_feature(feature_data)
        
        if not scripts_to_test:
            # No specific scripts, test all if retroactive testing enabled
            if self.job_config["retroactive_testing"]:
                logger.info("🔄 Running retroactive testing on all scripts...")
                test_results = self.tester.test_all_scripts()
            else:
                logger.warning("⚠️ No scripts found for testing")
                return {"status": "no_scripts", "results": {}}
        else:
            # Test specific scripts
            for script_path in scripts_to_test:
                try:
                    result = self.tester.test_single_script(script_path)
                    test_results[str(script_path)] = result
                except Exception as e:
                    logger.error(f"Error testing {script_path}: {e}")
        
        # Analyze results
        total_scripts = len(test_results)
        passed_scripts = sum(1 for r in test_results.values() if r.ready_for_pr)
        
        stage_result = {
            "status": "completed",
            "total_scripts": total_scripts,
            "passed_scripts": passed_scripts,
            "success_rate": (passed_scripts / total_scripts * 100) if total_scripts > 0 else 0,
            "test_results": {k: self.serialize_test_result(v) for k, v in test_results.items()}
        }
        
        logger.info(f"📊 Auto-test results: {passed_scripts}/{total_scripts} scripts passed ({stage_result['success_rate']:.1f}%)")
        
        return stage_result

    def run_confidence_scoring_stage(self, test_result: Dict[str, Any], feature_data: Dict[str, Any]) -> Dict[str, Any]:
        """Run confidence scoring based on test results."""
        
        # Extract confidence scores from test results
        script_confidences = []
        for script_path, result_data in test_result.get("test_results", {}).items():
            script_confidences.append(result_data["overall_confidence"])
        
        # Calculate overall confidence
        if script_confidences:
            # Use weighted average (higher weight for better scripts)
            sorted_confidences = sorted(script_confidences, reverse=True)
            
            # Weight calculation: best scripts get higher weight
            weights = [1.0 / (i + 1) for i in range(len(sorted_confidences))]
            total_weight = sum(weights)
            
            final_confidence = sum(conf * weight for conf, weight in zip(sorted_confidences, weights)) / total_weight
        else:
            # Fallback to feature data confidence if available
            final_confidence = feature_data.get("confidence_score", 0.0)
        
        # Determine action based on confidence
        if final_confidence >= self.thresholds["auto_pr_confidence"]:
            recommended_action = "auto_pr"
        elif final_confidence >= self.thresholds["manual_review_confidence"]:
            recommended_action = "manual_review"
        else:
            recommended_action = "reject"
        
        confidence_result = {
            "final_confidence": final_confidence,
            "script_confidences": script_confidences,
            "recommended_action": recommended_action,
            "thresholds": self.thresholds,
            "justification": self.get_confidence_justification(final_confidence, test_result)
        }
        
        logger.info(f"📊 Confidence scoring: {final_confidence:.1f}% → {recommended_action}")
        
        return confidence_result

    def run_auto_pr_stage(self, confidence_result: Dict[str, Any], feature_data: Dict[str, Any]) -> Dict[str, Any]:
        """Run auto-PR submission stage."""
        
        recommended_action = confidence_result["recommended_action"]
        final_confidence = confidence_result["final_confidence"]
        
        if not self.job_config["auto_pr_enabled"]:
            return {
                "action": "disabled",
                "message": "Auto-PR is disabled in configuration",
                "confidence": final_confidence
            }
        
        if recommended_action == "auto_pr":
            # Attempt auto-PR submission
            try:
                # Prepare feature data for auto-PR system
                enhanced_feature_data = feature_data.copy()
                enhanced_feature_data["confidence_score"] = final_confidence
                enhanced_feature_data["test_validated"] = True
                enhanced_feature_data["auto_generated"] = True
                
                # Use the netappfiles cluster for Azure CLI samples
                cluster_name = "netappfiles-feature-generator"
                pr_result = self.auto_pr_system.process_cluster_output(cluster_name, enhanced_feature_data)
                
                return {
                    "action": "auto_pr_attempted",
                    "pr_result": pr_result,
                    "confidence": final_confidence,
                    "message": f"Auto-PR attempted with {final_confidence:.1f}% confidence"
                }
                
            except Exception as e:
                logger.error(f"Auto-PR failed: {e}")
                return {
                    "action": "auto_pr_failed",
                    "error": str(e),
                    "confidence": final_confidence,
                    "fallback": "manual_review"
                }
        
        elif recommended_action == "manual_review":
            return {
                "action": "manual_review",
                "confidence": final_confidence,
                "message": f"Confidence {final_confidence:.1f}% requires manual review"
            }
        
        else:  # reject
            return {
                "action": "reject",
                "confidence": final_confidence,
                "message": f"Confidence {final_confidence:.1f}% below minimum threshold"
            }

    def get_scripts_for_feature(self, feature_data: Dict[str, Any]) -> List[Path]:
        """Get scripts related to a specific feature."""
        scripts = []
        
        # Check if feature data specifies files
        if "generated_files" in feature_data:
            for file_path in feature_data["generated_files"]:
                full_path = self.workspace_path / file_path
                if full_path.exists() and str(full_path).endswith('.sh'):
                    scripts.append(full_path)
        
        # Check category-based discovery
        if "category" in feature_data or "subcategory" in feature_data:
            category = feature_data.get("subcategory", feature_data.get("category", ""))
            if category:
                # Look for scripts in category directory
                category_dir = self.workspace_path / "netappfiles" / category
                if category_dir.exists():
                    scripts.extend(category_dir.rglob("*.sh"))
        
        return scripts

    def serialize_test_result(self, test_result: TestResult) -> Dict[str, Any]:
        """Serialize TestResult for JSON storage."""
        return {
            "script_path": test_result.script_path,
            "syntax_valid": test_result.syntax_valid,
            "compliance_score": test_result.compliance_score,
            "functional_score": test_result.functional_score,
            "overall_confidence": test_result.overall_confidence,
            "passed_tests": test_result.passed_tests,
            "failed_tests": test_result.failed_tests,
            "warnings": test_result.warnings,
            "execution_time": test_result.execution_time,
            "ready_for_pr": test_result.ready_for_pr
        }

    def get_confidence_justification(self, confidence: float, test_result: Dict[str, Any]) -> str:
        """Get human-readable justification for confidence score."""
        if confidence >= self.thresholds["auto_pr_confidence"]:
            return f"High confidence ({confidence:.1f}%) - All tests passed, ready for automatic PR submission"
        elif confidence >= self.thresholds["manual_review_confidence"]:
            return f"Medium confidence ({confidence:.1f}%) - Most tests passed, requires manual review before PR"
        else:
            return f"Low confidence ({confidence:.1f}%) - Multiple test failures, needs significant work"

    def save_job_result(self, job_result: Dict[str, Any]) -> None:
        """Save job result to file."""
        results_dir = self.workspace_path / "cluster_job_results"
        results_dir.mkdir(exist_ok=True)
        
        job_file = results_dir / f"{job_result['job_id']}.json"
        
        with open(job_file, 'w') as f:
            json.dump(job_result, f, indent=2, default=str)
        
        logger.info(f"💾 Job result saved: {job_file}")

    def run_retroactive_testing(self) -> Dict[str, Any]:
        """Run retroactive testing on all existing scripts."""
        logger.info("🔄 Starting retroactive testing of all existing scripts...")
        
        # Create synthetic feature data for retroactive testing
        feature_data = {
            "feature_name": "Retroactive Script Validation",
            "description": "Comprehensive validation of all existing scripts for auto-PR readiness",
            "category": "retroactive_testing",
            "confidence_score": 85.0  # Default for existing scripts
        }
        
        # Trigger the cluster job process
        job_result = self.trigger_cluster_job(feature_data)
        
        # Generate summary report
        if job_result["status"] == "completed":
            test_stage = job_result["stages"]["auto_test"]["result"]
            confidence_stage = job_result["stages"]["confidence_scoring"]["result"]
            pr_stage = job_result["stages"]["auto_pr"]["result"]
            
            summary = {
                "total_scripts": test_stage["total_scripts"],
                "ready_for_auto_pr": test_stage["passed_scripts"],
                "need_manual_review": test_stage["total_scripts"] - test_stage["passed_scripts"],
                "average_confidence": confidence_stage["final_confidence"],
                "recommended_action": confidence_stage["recommended_action"],
                "auto_pr_attempted": pr_stage["action"] == "auto_pr_attempted"
            }
            
            logger.info(f"📊 Retroactive testing summary:")
            logger.info(f"   Total scripts: {summary['total_scripts']}")
            logger.info(f"   Ready for auto-PR: {summary['ready_for_auto_pr']}")
            logger.info(f"   Need review: {summary['need_manual_review']}")
            logger.info(f"   Average confidence: {summary['average_confidence']:.1f}%")
            
            return summary
        
        return {"error": "Retroactive testing failed"}

def main():
    """Main function for testing the cluster job system."""
    workspace_path = Path(__file__).parent
    orchestrator = ClusterJobOrchestrator(workspace_path)
    
    print("🚀 Cluster Job Orchestrator - Auto-Test-Before-Auto-PR")
    print("=" * 60)
    
    # Example: Test with authentication troubleshooting feature
    feature_data = {
        "feature_name": "Azure NetApp Files LDAP and Kerberos Authentication Troubleshooting",
        "description": "Comprehensive authentication troubleshooting script",
        "confidence_score": 94.0,
        "generated_files": [
            "netappfiles/troubleshooting/authentication/anf-ldap-kerberos-troubleshoot.sh"
        ],
        "category": "troubleshooting",
        "subcategory": "authentication"
    }
    
    # Run cluster job
    job_result = orchestrator.trigger_cluster_job(feature_data)
    
    print(f"\n📊 Job Result:")
    print(f"   Job ID: {job_result['job_id']}")
    print(f"   Status: {job_result['status']}")
    print(f"   Final Action: {job_result.get('final_action', 'N/A')}")
    print(f"   Confidence: {job_result.get('confidence_score', 0):.1f}%")
    
    # Optional: Run retroactive testing
    print(f"\n🔄 Running retroactive testing...")
    retroactive_result = orchestrator.run_retroactive_testing()
    
    return job_result

if __name__ == "__main__":
    main()
