#!/bin/bash

# Cisco Catalyst Center PNP Automation - Environment Setup Script
# This script sets up the complete environment for running PNP automation
# Compatible with Ubuntu 20.04+ and modern Linux distributions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project information
PROJECT_NAME="Cisco Catalyst Center PNP Automation"
PROJECT_VERSION="2.0.0"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}${PROJECT_NAME} - Environment Setup${NC}"
echo -e "${BLUE}Version: ${PROJECT_VERSION}${NC}"
echo -e "${BLUE}============================================================${NC}"

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${PURPLE}[SUCCESS]${NC} $1"
}

# Function to check command availability
check_command() {
    local cmd=$1
    local name=${2:-$1}
    
    if command -v $cmd >/dev/null 2>&1; then
        print_status "$name is available: $(which $cmd)"
        return 0
    else
        print_error "$name is not available. Please install it first."
        return 1
    fi
}

# Check if we're in the correct directory
if [ ! -f "requirements.txt" ] || [ ! -d "ansible" ]; then
    print_error "This script must be run from the project root directory"
    print_error "Current directory: $PROJECT_DIR"
    print_error "Please clone the repository and run this script from the root directory"
    exit 1
fi

print_status "Project directory: $PROJECT_DIR"

# System validation
print_step "Validating system requirements..."

# Check operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    print_status "Operating System: $NAME $VERSION"
else
    print_warning "Could not detect operating system version"
fi

# Check essential commands
print_step "Checking essential tools..."
check_command python3 "Python 3" || exit 1
check_command pip3 "pip3" || exit 1
check_command ansible "Ansible" || exit 1
check_command git "Git" || exit 1

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
print_status "Python version: $python_version"

# Check minimum Python version (3.8)
python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)" 2>/dev/null
if [ $? -ne 0 ]; then
    print_error "Python 3.8 or higher is required. Current version: $python_version"
    print_error "Please upgrade Python before continuing."
    exit 1
fi

# Check Ansible version
ansible_version=$(ansible --version | head -1 | awk '{print $3}' | cut -d']' -f1 | cut -d'[' -f1)
print_status "Ansible version: $ansible_version"

# Check network connectivity
print_step "Testing network connectivity..."
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    print_status "Internet connectivity: OK"
else
    print_warning "Internet connectivity test failed. This may affect package installation."
fi

# Check DNS resolution
if nslookup github.com >/dev/null 2>&1; then
    print_status "DNS resolution: OK"
else
    print_warning "DNS resolution test failed. This may affect package installation."
fi

# Python virtual environment setup
print_step "Setting up Python virtual environment..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_status "Creating new virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_status "Virtual environment already exists"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip first
print_status "Upgrading pip to latest version..."
pip install --upgrade pip

# Check if requirements need to be installed
requirements_hash=""
if [ -f "requirements.txt" ]; then
    requirements_hash=$(sha256sum requirements.txt | awk '{print $1}')
fi

install_requirements=true
if [ -f "venv/.requirements_hash" ]; then
    stored_hash=$(cat venv/.requirements_hash)
    if [ "$requirements_hash" = "$stored_hash" ]; then
        print_status "Requirements are already up to date"
        install_requirements=false
    fi
fi

if [ "$install_requirements" = true ]; then
    print_status "Installing Python requirements..."
    pip install -r requirements.txt
    echo "$requirements_hash" > venv/.requirements_hash
    print_success "Python requirements installed successfully"
fi

# Ansible collections setup
print_step "Setting up Ansible collections..."

collections_needed=(
    "cisco.dnac"
    "cisco.ios" 
    "community.general"
    "ansible.posix"
    "ansible.utils"
    "ansible.netcommon"
)

# Create collections requirements file
cat > ansible-requirements.yml << 'EOF'
---
collections:
  - name: cisco.dnac
    version: ">=6.7.0"
  - name: cisco.ios
    version: ">=4.6.0"
  - name: community.general
    version: ">=6.0.0"
  - name: ansible.posix
    version: ">=1.4.0"
  - name: ansible.utils
    version: ">=2.8.0"
  - name: ansible.netcommon
    version: ">=4.1.0"
EOF

# Install collections from requirements file
print_status "Installing Ansible collections from requirements..."
ansible-galaxy collection install -r ansible-requirements.yml --force

# Verify collections installation
print_status "Verifying installed collections..."
for collection in "${collections_needed[@]}"; do
    if ansible-galaxy collection list | grep -q "$collection"; then
        version=$(ansible-galaxy collection list | grep "$collection" | awk '{print $2}')
        print_status "✓ $collection $version"
    else
        print_warning "✗ $collection - Installation failed"
    fi
done

# Project structure verification
print_step "Verifying project structure..."

required_dirs=(
    "ansible/playbooks"
    "ansible/inventory"
    "configs" 
    "docs"
    "scripts"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_status "✓ Directory exists: $dir"
    else
        print_warning "✗ Directory missing: $dir"
        mkdir -p "$dir"
        print_status "Created directory: $dir"
    fi
done

# Check configuration files
print_step "Checking configuration files..."

config_files=(
    "ansible/ansible.cfg"
    "ansible/inventory/hosts.yml"
    "configs/config.example.yml"
)

for config in "${config_files[@]}"; do
    if [ -f "$config" ]; then
        print_status "✓ Configuration file exists: $config"
    else
        print_warning "✗ Configuration file missing: $config"
    fi
done

# Create example inventory if missing
if [ ! -f "ansible/inventory/hosts.yml" ]; then
    print_status "Creating example inventory file..."
    mkdir -p ansible/inventory/{group_vars,host_vars}
    
    cat > ansible/inventory/hosts.yml << 'EOF'
---
# Cisco Catalyst Center PNP Automation Inventory
# Update this file with your environment details

all:
  children:
    catalyst_center:
      hosts:
        dnac_primary:
          ansible_host: "192.168.1.100"      # Update with Catalyst Center IP
          ansible_user: "admin"               # Update with API username
          ansible_password: "Cisco123!"       # Update with API password
          ansible_connection: local
          dnac_verify: false
          dnac_version: "3.1.0"
          
    network_devices:
      hosts:
        device_001:
          serial_number: "FCH1234ABCD"       # Update with device serial
          hostname: "branch-router-01"       # Update with device hostname
          site_hierarchy: "Global/Region_01/Branch_01"
          device_type: "Cisco Catalyst 8000V"
          management_ip: "192.168.100.10"
          
  vars:
    ansible_python_interpreter: "{{ ansible_playbook_python }}"
    gather_facts: false
EOF
    
    print_success "Created example inventory: ansible/inventory/hosts.yml"
    print_warning "Please update this file with your environment details before running playbooks"
fi

# Environment validation
print_step "Running environment validation..."

# Test Ansible functionality
if ansible localhost -m ping >/dev/null 2>&1; then
    print_status "✓ Ansible functionality: Working"
else
    print_warning "✗ Ansible functionality: Issue detected"
fi

# Test Python imports
python3 -c "
try:
    import requests, yaml, jinja2, dnac_sdk
    print('✓ All Python dependencies available')
except ImportError as e:
    print(f'✗ Python dependency issue: {e}')
" 2>/dev/null || print_warning "Some Python dependencies may be missing"

# Final setup completion
print_step "Environment setup completed successfully!"

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}🎉 Setup Summary${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "📁 Project Directory: ${CYAN}${PROJECT_DIR}${NC}"
echo -e "🐍 Python Version: ${CYAN}${python_version}${NC}"
echo -e "⚡ Virtual Environment: ${GREEN}Active${NC}"
echo -e "🤖 Ansible Version: ${CYAN}${ansible_version}${NC}"
echo -e "📦 Collections: ${GREEN}Installed${NC}"
echo -e "📋 Configuration: ${GREEN}Ready${NC}"
echo ""

echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "1. 📝 Update ${CYAN}ansible/inventory/hosts.yml${NC} with your environment details"
echo -e "2. 🔗 Test connectivity to Catalyst Center"
echo -e "3. 🚀 Run PNP automation playbooks"
echo ""

echo -e "${PURPLE}💡 Quick Commands:${NC}"
echo -e "• Activate environment: ${CYAN}source venv/bin/activate${NC}"
echo -e "• Test connectivity: ${CYAN}ansible catalyst_center -i ansible/inventory/hosts.yml -m ping${NC}"
echo -e "• Run PNP onboarding: ${CYAN}ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml${NC}"
echo -e "• View documentation: ${CYAN}less docs/ANSIBLE_DEPLOYMENT_GUIDE.md${NC}"
echo ""

echo -e "${BLUE}📚 Documentation Available:${NC}"
echo -e "• Ubuntu Setup: ${CYAN}docs/UBUNTU_ADMIN_PC_SETUP.md${NC}"
echo -e "• Complete Guide: ${CYAN}docs/ANSIBLE_DEPLOYMENT_GUIDE.md${NC}"
echo -e "• Quick Start: ${CYAN}QUICK_START.md${NC}"
echo -e "• API Reference: ${CYAN}docs/API_REFERENCE.md${NC}"
echo -e "• Troubleshooting: ${CYAN}docs/TROUBLESHOOTING.md${NC}"
echo ""

echo -e "${GREEN}🎯 Environment is ready for Cisco Catalyst Center PNP automation!${NC}"
echo -e "${PURPLE}To get started, run: ${CYAN}source venv/bin/activate${NC}"
echo ""

# Create activation script for convenience
cat > activate_environment.sh << 'EOF'
#!/bin/bash
# Cisco Catalyst Center PNP Automation - Environment Activation
echo "Activating Cisco Catalyst Center PNP Automation environment..."
source venv/bin/activate
echo "Environment activated! You can now run Ansible playbooks."
echo "Type 'deactivate' to exit the virtual environment."
EOF

chmod +x activate_environment.sh
print_success "Created activation script: ./activate_environment.sh"