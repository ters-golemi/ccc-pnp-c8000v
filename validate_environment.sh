#!/bin/bash

# Cisco Catalyst Center PNP Automation - Environment Validation Script
# This script validates the complete environment setup and readiness

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Cisco Catalyst Center PNP Environment Validation${NC}"
echo -e "${BLUE}============================================================${NC}"

# Function to print status messages
print_check() {
    local status=$1
    local message=$2
    
    if [ "$status" = "pass" ]; then
        echo -e "✅ ${GREEN}PASS${NC} - $message"
    elif [ "$status" = "fail" ]; then
        echo -e "❌ ${RED}FAIL${NC} - $message"
    elif [ "$status" = "warn" ]; then
        echo -e "⚠️  ${YELLOW}WARN${NC} - $message"
    elif [ "$status" = "info" ]; then
        echo -e "ℹ️  ${CYAN}INFO${NC} - $message"
    fi
}

# Track results
passed=0
failed=0
warnings=0

# System Requirements Check
echo -e "\n${YELLOW}🖥️  System Requirements${NC}"

# Check operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_check "info" "Operating System: $NAME $VERSION"
else
    print_check "warn" "Could not detect operating system"
    ((warnings++))
fi

# Check CPU cores
cpu_cores=$(nproc)
if [ "$cpu_cores" -ge 2 ]; then
    print_check "pass" "CPU Cores: $cpu_cores (minimum 2 required)"
    ((passed++))
else
    print_check "fail" "CPU Cores: $cpu_cores (minimum 2 required)"
    ((failed++))
fi

# Check memory
memory_gb=$(free -g | awk '/^Mem:/ {print $2}')
if [ "$memory_gb" -ge 4 ]; then
    print_check "pass" "Memory: ${memory_gb}GB (minimum 4GB required)"
    ((passed++))
else
    print_check "fail" "Memory: ${memory_gb}GB (minimum 4GB required)"
    ((failed++))
fi

# Check disk space
disk_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$disk_space" -ge 20 ]; then
    print_check "pass" "Available Disk Space: ${disk_space}GB (minimum 20GB required)"
    ((passed++))
else
    print_check "fail" "Available Disk Space: ${disk_space}GB (minimum 20GB required)"
    ((failed++))
fi

# Essential Tools Check
echo -e "\n${YELLOW}🔧 Essential Tools${NC}"

tools=("python3:Python 3" "pip3:pip3" "ansible:Ansible" "git:Git" "curl:curl" "ssh:SSH")

for tool_info in "${tools[@]}"; do
    IFS=':' read -r cmd name <<< "$tool_info"
    if command -v "$cmd" >/dev/null 2>&1; then
        version=""
        case "$cmd" in
            python3) version=" ($(python3 --version | awk '{print $2}'))" ;;
            ansible) version=" ($(ansible --version | head -1 | awk '{print $3}' | cut -d']' -f1 | cut -d'[' -f1))" ;;
            git) version=" ($(git --version | awk '{print $3}'))" ;;
        esac
        print_check "pass" "$name available$version"
        ((passed++))
    else
        print_check "fail" "$name not found"
        ((failed++))
    fi
done

# Python Version Check
echo -e "\n${YELLOW}🐍 Python Environment${NC}"

python_version=$(python3 --version 2>&1 | awk '{print $2}')
if python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)" 2>/dev/null; then
    print_check "pass" "Python version $python_version (3.8+ required)"
    ((passed++))
else
    print_check "fail" "Python version $python_version (3.8+ required)"
    ((failed++))
fi

# Check virtual environment
if [ -d "venv" ]; then
    print_check "pass" "Virtual environment exists"
    ((passed++))
    
    if [ -f "venv/pyvenv.cfg" ]; then
        print_check "pass" "Virtual environment configured"
        ((passed++))
    else
        print_check "fail" "Virtual environment corrupted"
        ((failed++))
    fi
else
    print_check "fail" "Virtual environment missing"
    ((failed++))
fi

# Check Python packages (if venv exists)
if [ -d "venv" ]; then
    source venv/bin/activate 2>/dev/null
    
    packages=("requests" "yaml" "jinja2" "dnac_sdk" "ansible")
    for package in "${packages[@]}"; do
        if python3 -c "import $package" 2>/dev/null; then
            print_check "pass" "Python package: $package"
            ((passed++))
        else
            print_check "fail" "Python package missing: $package"
            ((failed++))
        fi
    done
fi

# Ansible Collections Check
echo -e "\n${YELLOW}📦 Ansible Collections${NC}"

collections=("cisco.dnac" "cisco.ios" "community.general" "ansible.posix" "ansible.utils" "ansible.netcommon")

for collection in "${collections[@]}"; do
    if ansible-galaxy collection list 2>/dev/null | grep -q "$collection"; then
        version=$(ansible-galaxy collection list | grep "$collection" | awk '{print $2}')
        print_check "pass" "Collection: $collection $version"
        ((passed++))
    else
        print_check "fail" "Collection missing: $collection"
        ((failed++))
    fi
done

# Project Structure Check
echo -e "\n${YELLOW}📁 Project Structure${NC}"

required_files=(
    "requirements.txt:Requirements file"
    "setup_environment.sh:Setup script"
    "ansible/ansible.cfg:Ansible configuration"
    "docs/ANSIBLE_DEPLOYMENT_GUIDE.md:Deployment guide"
    "docs/UBUNTU_ADMIN_PC_SETUP.md:Ubuntu setup guide"
    "QUICK_START.md:Quick start guide"
)

for file_info in "${required_files[@]}"; do
    IFS=':' read -r file desc <<< "$file_info"
    if [ -f "$file" ]; then
        print_check "pass" "$desc exists"
        ((passed++))
    else
        print_check "fail" "$desc missing: $file"
        ((failed++))
    fi
done

required_dirs=(
    "ansible/playbooks:Playbooks directory"
    "ansible/inventory:Inventory directory" 
    "configs:Configuration directory"
    "docs:Documentation directory"
    "scripts:Scripts directory"
)

for dir_info in "${required_dirs[@]}"; do
    IFS=':' read -r dir desc <<< "$dir_info"
    if [ -d "$dir" ]; then
        print_check "pass" "$desc exists"
        ((passed++))
    else
        print_check "fail" "$desc missing: $dir"
        ((failed++))
    fi
done

# Network Connectivity Check
echo -e "\n${YELLOW}🌐 Network Connectivity${NC}"

# DNS Resolution
if nslookup google.com >/dev/null 2>&1; then
    print_check "pass" "DNS resolution working"
    ((passed++))
else
    print_check "fail" "DNS resolution failed"
    ((failed++))
fi

# Internet connectivity
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    print_check "pass" "Internet connectivity working"
    ((passed++))
else
    print_check "fail" "Internet connectivity failed"
    ((failed++))
fi

# HTTPS connectivity
if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    print_check "pass" "HTTPS connectivity working"
    ((passed++))
else
    print_check "fail" "HTTPS connectivity failed"
    ((failed++))
fi

# Configuration Check
echo -e "\n${YELLOW}⚙️  Configuration${NC}"

# Check Ansible configuration
if [ -f "ansible/ansible.cfg" ]; then
    print_check "pass" "Ansible configuration file exists"
    ((passed++))
else
    print_check "fail" "Ansible configuration missing"
    ((failed++))
fi

# Check inventory example
if [ -f "ansible/inventory/hosts.yml" ]; then
    print_check "pass" "Inventory file exists"
    ((passed++))
    
    # Check if inventory has been customized
    if grep -q "192.168.1.100" ansible/inventory/hosts.yml 2>/dev/null; then
        print_check "warn" "Inventory still has example values - needs customization"
        ((warnings++))
    else
        print_check "pass" "Inventory appears to be customized"
        ((passed++))
    fi
else
    print_check "fail" "Inventory file missing"
    ((failed++))
fi

# Ansible Functionality Test
echo -e "\n${YELLOW}🤖 Ansible Functionality${NC}"

if ansible localhost -m ping >/dev/null 2>&1; then
    print_check "pass" "Ansible ping test successful"
    ((passed++))
else
    print_check "fail" "Ansible ping test failed"
    ((failed++))
fi

# Final Results
echo -e "\n${BLUE}============================================================${NC}"
echo -e "${BLUE}📊 Validation Results${NC}"
echo -e "${BLUE}============================================================${NC}"

total_checks=$((passed + failed + warnings))
pass_rate=$(( (passed * 100) / (passed + failed) ))

echo -e "✅ ${GREEN}Passed:${NC} $passed"
echo -e "❌ ${RED}Failed:${NC} $failed"
echo -e "⚠️  ${YELLOW}Warnings:${NC} $warnings"
echo -e "📊 ${CYAN}Total Checks:${NC} $total_checks"
echo -e "📈 ${PURPLE}Pass Rate:${NC} $pass_rate%"

echo ""
if [ "$failed" -eq 0 ]; then
    echo -e "${GREEN}🎉 Environment validation PASSED!${NC}"
    echo -e "${GREEN}Your system is ready for Cisco Catalyst Center PNP automation.${NC}"
    
    if [ "$warnings" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Please review the warnings above.${NC}"
    fi
    
    exit 0
else
    echo -e "${RED}❌ Environment validation FAILED!${NC}"
    echo -e "${RED}Please resolve the failed checks before proceeding.${NC}"
    
    echo -e "\n${CYAN}💡 Suggested Actions:${NC}"
    echo -e "1. Run: ${YELLOW}./setup_environment.sh${NC}"
    echo -e "2. Check: ${YELLOW}docs/UBUNTU_ADMIN_PC_SETUP.md${NC}"
    echo -e "3. Verify: ${YELLOW}docs/TROUBLESHOOTING.md${NC}"
    
    exit 1
fi