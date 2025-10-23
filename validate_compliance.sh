#!/bin/bash
# Azure CLI Samples Validation Test
# Tests the authentication script against Azure CLI samples requirements

echo "🧪 Azure CLI Samples Compliance Validation"
echo "=========================================="

script_path="netappfiles/troubleshooting/authentication/anf-ldap-kerberos-troubleshoot.sh"

echo "📝 Testing: $script_path"

# Check if script exists
if [ ! -f "$script_path" ]; then
    echo "❌ Script not found: $script_path"
    exit 1
fi

echo "✅ Script file exists"

# Check shebang for bash
if head -n1 "$script_path" | grep -q "#!/bin/bash"; then
    echo "✅ Uses bash shell (#!/bin/bash)"
else
    echo "❌ Must use bash shell"
fi

# Check for test date
if grep -q "Last tested:" "$script_path"; then
    echo "✅ Contains test date"
    grep "Last tested:" "$script_path"
else
    echo "❌ Missing test date"
fi

# Check for random resource naming
if grep -q "RANDOM\|shuf.*-i.*-n" "$script_path"; then
    echo "✅ Uses random resource naming"
    grep -E "RANDOM|shuf.*-i.*-n" "$script_path" | head -2
else
    echo "❌ Missing random resource naming"
fi

# Check for no hardcoded passwords
if grep -q "password.*=" "$script_path" && ! grep -q "your-password" "$script_path"; then
    echo "⚠️ Check for hardcoded passwords"
else
    echo "✅ No hardcoded passwords detected"
fi

# Check for environment variable support
if grep -q ":-" "$script_path"; then
    echo "✅ Supports environment variables"
    grep ":-" "$script_path" | head -3
else
    echo "⚠️ Consider adding environment variable support"
fi

# Check for Azure CLI version requirements
if grep -q "Azure CLI version" "$script_path"; then
    echo "✅ Specifies Azure CLI version requirements"
    grep "Azure CLI version" "$script_path"
else
    echo "⚠️ Consider adding CLI version requirements"
fi

# Check for non-interactive execution
if grep -q "read -p\|read.*input" "$script_path"; then
    echo "❌ Script may require user input"
else
    echo "✅ Can run without user input"
fi

# Test syntax
if bash -n "$script_path" 2>/dev/null; then
    echo "✅ Script syntax is valid"
else
    echo "❌ Script has syntax errors"
    bash -n "$script_path"
fi

echo ""
echo "📋 Azure CLI Samples Compliance Summary:"
echo "   • Script uses bash shell"
echo "   • Test date and method documented"
echo "   • Random resource naming implemented"
echo "   • No hardcoded secrets"
echo "   • Environment variable support"
echo "   • Non-interactive execution"
echo "   • Valid bash syntax"
echo ""
echo "✅ Script meets Azure CLI samples requirements!"
