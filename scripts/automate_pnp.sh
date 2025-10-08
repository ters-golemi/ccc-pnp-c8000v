#!/bin/bash
#
# Complete PNP Automation Wrapper Script
# Automates the entire PNP onboarding process
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/configs/config.yml"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if serial number is provided
if [ $# -eq 0 ]; then
    print_error "No serial number provided"
    echo "Usage: $0 <SERIAL_NUMBER>"
    echo "Example: $0 FCH1234ABCD"
    exit 1
fi

SERIAL_NUMBER=$1

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    print_info "Copy configs/config.example.yml to configs/config.yml and update it"
    exit 1
fi

# Check if Python virtual environment exists
if [ ! -d "$PROJECT_ROOT/venv" ]; then
    print_warning "Python virtual environment not found"
    print_info "Creating virtual environment..."
    python3 -m venv "$PROJECT_ROOT/venv"
    print_success "Virtual environment created"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source "$PROJECT_ROOT/venv/bin/activate"

# Check if dependencies are installed
if ! python3 -c "import requests" 2>/dev/null; then
    print_warning "Dependencies not installed"
    print_info "Installing dependencies..."
    pip install -r "$PROJECT_ROOT/requirements.txt"
    print_success "Dependencies installed"
fi

# Main automation workflow
print_header "PNP AUTOMATION WORKFLOW"
echo "Serial Number: $SERIAL_NUMBER"
echo "Config File: $CONFIG_FILE"
echo ""

# Step 1: Check device status
print_header "Step 1: Checking Device Status"
print_info "Looking up device in PNP..."

if python3 "$SCRIPT_DIR/pnp_monitor.py" --config "$CONFIG_FILE" --serial "$SERIAL_NUMBER" > /tmp/pnp_check.log 2>&1; then
    print_success "Device found in PNP"
    cat /tmp/pnp_check.log
else
    print_error "Device not found in PNP"
    print_info "Make sure the device has contacted Catalyst Center PNP service"
    print_info "Check DHCP Option 43 and network connectivity"
    exit 1
fi

echo ""
read -p "Continue with device claim? (yes/no): " CONTINUE
if [ "$CONTINUE" != "yes" ]; then
    print_warning "Operation cancelled by user"
    exit 0
fi

# Step 2: Claim device
print_header "Step 2: Claiming Device"
print_info "Claiming device to site..."

if python3 "$SCRIPT_DIR/pnp_claim_device.py" --config "$CONFIG_FILE" --serial "$SERIAL_NUMBER"; then
    print_success "Device claimed successfully"
else
    print_error "Device claim failed"
    exit 1
fi

# Step 3: Monitor provisioning
print_header "Step 3: Monitoring Provisioning"
print_info "Monitoring device provisioning status..."
print_info "This may take several minutes..."
print_info "Press Ctrl+C to stop monitoring"
echo ""

# Monitor for 5 minutes (300 seconds) with 30 second intervals
python3 "$SCRIPT_DIR/pnp_monitor.py" --config "$CONFIG_FILE" --serial "$SERIAL_NUMBER" --watch --interval 30 --duration 300 || true

# Final status check
print_header "Step 4: Final Status Check"
print_info "Checking final device status..."

python3 "$SCRIPT_DIR/pnp_monitor.py" --config "$CONFIG_FILE" --serial "$SERIAL_NUMBER"

print_header "AUTOMATION COMPLETE"
print_success "PNP automation workflow completed"
print_info "Check Catalyst Center for device provisioning status"
print_info "Navigate to: Provision > Plug and Play"

# Deactivate virtual environment
deactivate
