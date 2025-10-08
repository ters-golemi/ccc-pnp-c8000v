#!/bin/bash

# Cisco Catalyst Center PNP Automation - Project Activation Script
# This script sets up the complete environment for running PNP automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project information
PROJECT_NAME="Cisco Catalyst Center PNP Automation"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}${PROJECT_NAME}${NC}"
echo -e "${BLUE}========================================${NC}"

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

# Check if we're in the correct directory
if [ ! -f "requirements.txt" ] || [ ! -d "ansible" ]; then
    print_error "This script must be run from the project root directory"
    print_error "Current directory: $PROJECT_DIR"
    exit 1
fi

print_status "Project directory: $PROJECT_DIR"

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
print_status "Python version: $python_version"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_warning "Virtual environment not found. Creating new environment..."
    python3 -m venv venv
    print_status "Virtual environment created"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Check if requirements are installed
if [ ! -f "venv/pyvenv.cfg" ] || [ ! -f "venv/.requirements_installed" ]; then
    print_status "Installing Python requirements..."
    pip install --upgrade pip
    pip install -r requirements.txt
    touch venv/.requirements_installed
    print_status "Requirements installed successfully"
else
    print_status "Python requirements already installed"
fi

# Check Ansible version
ansible_version=$(ansible --version 2>/dev/null | head -1 | awk '{print $2}' || echo "Not installed")
if [ "$ansible_version" == "Not installed" ]; then
    print_warning "Ansible not found in system PATH"
    print_status "Installing Ansible in virtual environment..."
    pip install ansible
else
    print_status "Ansible version: $ansible_version"
fi

# Check and install Ansible collections
print_status "Checking Ansible collections..."

collections_needed=(
    "cisco.dnac"
    "cisco.ios" 
    "community.general"
    "ansible.posix"
)

for collection in "${collections_needed[@]}"; do
    if ansible-galaxy collection list | grep -q "$collection"; then
        print_status "Collection $collection is installed"
    else
        print_status "Installing collection: $collection"
        ansible-galaxy collection install "$collection"
    fi
done

# Verify inventory structure
print_status "Checking project structure..."

required_dirs=(
    "ansible/playbooks"
    "configs"
    "docs"
    "scripts"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_status "Directory exists: $dir"
    else
        print_warning "Directory missing: $dir"
    fi
done

# Check for inventory file
if [ ! -d "inventory" ]; then
    print_warning "Inventory directory not found. Creating structure..."
    mkdir -p inventory/{group_vars,host_vars}
    
    if [ ! -f "inventory/hosts.yml" ]; then
        print_status "Creating example inventory file..."
        cat > inventory/hosts.yml << 'EOF'
---
# Example inventory file - Update with your environment details
all:
  children:
    dnac:
      hosts:
        catalyst_center:
          ansible_host: "192.168.1.100"  # Update with your Catalyst Center IP
          ansible_user: "admin"          # Update with your API username
          ansible_password: "Cisco123!"  # Update with your API password
          ansible_connection: local
    
    devices:
      hosts:
        target_device:
          serial_number: "FCH1234ABCD"   # Update with device serial number
          hostname: "branch-router-01"   # Update with desired hostname
          site: "Global/Region_01/Branch_01"  # Update with site hierarchy
          device_type: "Cisco Catalyst 8000V"
EOF
        print_warning "Created example inventory file: inventory/hosts.yml"
        print_warning "Please update this file with your environment details"
    fi
fi

# Test basic connectivity (if inventory exists with proper values)
print_status "Environment setup complete!"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Environment Status Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Project Directory: ${PROJECT_DIR}"
echo -e "Python Version: ${python_version}"
echo -e "Virtual Environment: ${GREEN}Active${NC}"
echo -e "Ansible Version: ${ansible_version}"
echo -e "Required Collections: ${GREEN}Installed${NC}"

echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "1. Update inventory/hosts.yml with your environment details"
echo -e "2. Test connectivity: ${YELLOW}ansible catalyst_center -i inventory/hosts.yml -m ping${NC}"
echo -e "3. Run deployment: ${YELLOW}ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml${NC}"

echo -e "\n${BLUE}Documentation:${NC}"
echo -e "- Complete Guide: ${YELLOW}docs/ANSIBLE_DEPLOYMENT_GUIDE.md${NC}"
echo -e "- Quick Start: ${YELLOW}QUICK_START.md${NC}"
echo -e "- API Reference: ${YELLOW}docs/API_REFERENCE.md${NC}"

echo -e "\n${GREEN}Environment ready for PNP automation!${NC}"

# Keep the virtual environment activated for the user
exec "$SHELL"