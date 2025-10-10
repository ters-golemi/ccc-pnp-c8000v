# Ubuntu Admin PC Preparation for Cisco Catalyst Center PNP Deployment

This procedure provides step-by-step instructions to prepare an Ubuntu administrative workstation for Cisco Catalyst Center PNP (Plug and Play) automation deployment.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Initial System Setup](#initial-system-setup)
3. [Python Environment Preparation](#python-environment-preparation)
4. [Ansible Installation and Configuration](#ansible-installation-and-configuration)
5. [Network Tools and Dependencies](#network-tools-and-dependencies)
6. [SSH and Security Configuration](#ssh-and-security-configuration)
7. [Environment Validation](#environment-validation)
8. [Post-Setup Configuration](#post-setup-configuration)
9. [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## System Requirements

### Minimum Hardware Requirements
- **CPU:** 2 cores (4 cores recommended)
- **RAM:** 4GB minimum (8GB recommended)
- **Storage:** 20GB available disk space (50GB recommended)
- **Network:** Ethernet connection with internet access

### Operating System Requirements
- **Ubuntu 20.04 LTS** or later (22.04 LTS recommended)
- **Architecture:** x86_64 (AMD64)
- **User Account:** Administrative privileges (sudo access)

### Network Requirements
- **Internet Access:** For package downloads and updates
- **Management Network:** Layer 3 connectivity to Cisco Catalyst Center
- **DNS Resolution:** Functional DNS configuration
- **Firewall:** Outbound HTTPS (443) and SSH (22) access

---

## Initial System Setup

### Step 1: Update System Packages

```bash
# Update package repositories and installed packages
sudo apt update && sudo apt upgrade -y

# Remove unnecessary packages and clean cache
sudo apt autoremove -y && sudo apt autoclean

# Reboot if kernel was updated
if [ -f /var/run/reboot-required ]; then
    echo "System reboot required. Please reboot and continue."
    sudo reboot
fi
```

### Step 2: Install Essential System Packages

```bash
# Install essential development and system tools
sudo apt install -y \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    curl \
    wget \
    vim \
    nano \
    git \
    unzip \
    zip \
    tree \
    htop \
    screen \
    tmux

# Install build tools for Python packages
sudo apt install -y \
    build-essential \
    gcc \
    g++ \
    make \
    libc6-dev \
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev
```

### Step 3: Configure System Locale and Timezone

```bash
# Configure locale (adjust for your region)
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

# Set timezone (adjust for your location)
sudo timedatectl set-timezone UTC
# Or for specific timezone: sudo timedatectl set-timezone America/New_York

# Verify configuration
locale
timedatectl status
```

---

## Python Environment Preparation

### Step 1: Install Python and Related Tools

```bash
# Install Python 3 and development tools
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel

# Install Python package build dependencies
sudo apt install -y \
    python3-distutils \
    python3-apt \
    python-is-python3
```

### Step 2: Verify Python Installation

```bash
# Check Python version (should be 3.8 or higher)
python3 --version
pip3 --version

# Update pip to latest version
python3 -m pip install --upgrade pip

# Install essential Python packages
pip3 install --user \
    virtualenv \
    setuptools \
    wheel \
    certifi
```

### Step 3: Configure Python Environment Variables

```bash
# Add Python user bin directory to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Add Python environment variables
echo 'export PYTHONDONTWRITEBYTECODE=1' >> ~/.bashrc
echo 'export PYTHONUNBUFFERED=1' >> ~/.bashrc

# Reload shell configuration
source ~/.bashrc
```

---

## Ansible Installation and Configuration

### Step 1: Install Ansible via APT Repository

```bash
# Add Ansible official repository
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Update package list
sudo apt update

# Install Ansible and related tools
sudo apt install -y \
    ansible \
    ansible-doc \
    sshpass

# Verify Ansible installation
ansible --version
ansible-galaxy --version
```

### Step 2: Configure Ansible Global Settings

```bash
# Create Ansible configuration directory
mkdir -p ~/.ansible/{collections,roles,plugins}

# Create global Ansible configuration file
cat > ~/.ansible.cfg << 'EOF'
[defaults]
# Basic configuration
inventory = ./inventory
host_key_checking = False
timeout = 30
forks = 10
gathering = explicit
retry_files_enabled = False
stdout_callback = yaml
bin_ansible_callbacks = True

# Logging configuration
log_path = ./ansible.log
display_skipped_hosts = False
display_ok_hosts = True

# Connection settings
remote_user = admin
private_key_file = ~/.ssh/id_rsa

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
control_path = ~/.ssh/ansible-%%h-%%p-%%r

[persistent_connection]
command_timeout = 60
connect_timeout = 30

[colors]
highlight = white
verbose = blue
warn = bright purple
error = red
debug = dark gray
deprecate = purple
skip = cyan
unreachable = red
ok = green
changed = yellow
EOF
```

### Step 3: Install Required Ansible Collections

```bash
# Install Cisco-specific collections
ansible-galaxy collection install cisco.dnac --force
ansible-galaxy collection install cisco.ios --force

# Install community collections
ansible-galaxy collection install community.general --force
ansible-galaxy collection install ansible.posix --force
ansible-galaxy collection install ansible.utils --force

# Install network automation collections
ansible-galaxy collection install ansible.netcommon --force
ansible-galaxy collection install community.network --force

# Verify installed collections
ansible-galaxy collection list
```

---

## Network Tools and Dependencies

### Step 1: Install Network Diagnostic Tools

```bash
# Install network analysis and debugging tools
sudo apt install -y \
    net-tools \
    iputils-ping \
    iputils-tracepath \
    traceroute \
    nmap \
    netcat \
    telnet \
    tcpdump \
    wireshark-common \
    dnsutils \
    whois \
    arp-scan

# Install network performance tools
sudo apt install -y \
    iperf3 \
    mtr-tiny \
    ethtool \
    iftop \
    nethogs \
    ss
```

### Step 2: Install SSL/TLS and Cryptographic Tools

```bash
# Install SSL/TLS tools
sudo apt install -y \
    openssl \
    ca-certificates \
    ca-certificates-java

# Install additional cryptographic tools
sudo apt install -y \
    gnupg2 \
    gpg-agent \
    pass

# Update CA certificates
sudo update-ca-certificates
```

### Step 3: Configure Network Testing Scripts

```bash
# Create network connectivity test script
cat > ~/test_network.sh << 'EOF'
#!/bin/bash

echo "=== Network Connectivity Test ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "IP Configuration:"
ip addr show | grep -E "(inet|ether)" | head -10
echo ""

echo "=== DNS Resolution Test ==="
for host in google.com cisco.com github.com; do
    if nslookup $host >/dev/null 2>&1; then
        echo "✓ DNS resolution for $host: OK"
    else
        echo "✗ DNS resolution for $host: FAILED"
    fi
done
echo ""

echo "=== Internet Connectivity Test ==="
for host in 8.8.8.8 1.1.1.1; do
    if ping -c 2 $host >/dev/null 2>&1; then
        echo "✓ Ping to $host: OK"
    else
        echo "✗ Ping to $host: FAILED"
    fi
done
echo ""

echo "=== HTTPS Connectivity Test ==="
for url in https://google.com https://github.com; do
    if curl -s --connect-timeout 5 $url >/dev/null 2>&1; then
        echo "✓ HTTPS to $url: OK"
    else
        echo "✗ HTTPS to $url: FAILED"
    fi
done
EOF

chmod +x ~/test_network.sh
```

---

## SSH and Security Configuration

### Step 1: Configure SSH Client

```bash
# Install SSH client (if not already installed)
sudo apt install -y openssh-client

# Create SSH directory with proper permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key pair (if not exists)
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -N "" -f ~/.ssh/id_rsa
    echo "SSH key pair generated successfully"
fi

# Set proper SSH file permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Create SSH config file
cat > ~/.ssh/config << 'EOF'
# Global SSH configuration
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10

# Example Catalyst Center configuration
# Host catalyst-center
#     HostName 192.168.1.100
#     User admin
#     IdentityFile ~/.ssh/id_rsa
#     Port 22
EOF

chmod 600 ~/.ssh/config
```

### Step 2: Configure Firewall (UFW)

```bash
# Install and configure UFW firewall
sudo apt install -y ufw

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (if needed for remote management)
sudo ufw allow ssh

# Allow common outbound ports for automation
sudo ufw allow out 22    # SSH
sudo ufw allow out 53    # DNS
sudo ufw allow out 80    # HTTP
sudo ufw allow out 443   # HTTPS

# Enable firewall (optional - consider your network security policy)
# sudo ufw enable

# Check firewall status
sudo ufw status verbose
```

### Step 3: Security Hardening

```bash
# Install security tools
sudo apt install -y \
    fail2ban \
    unattended-upgrades \
    apt-listchanges

# Configure automatic security updates
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# Enable automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Check system security status
sudo aa-status 2>/dev/null || echo "AppArmor not available"
```

---

## Environment Validation

### Step 1: Create System Validation Script

```bash
# Create comprehensive system validation script
cat > ~/validate_environment.sh << 'EOF'
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Ubuntu Admin PC Environment Validation ===${NC}"
echo "Validation Date: $(date)"
echo "System: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo ""

# Function to check command availability
check_command() {
    local cmd=$1
    local name=${2:-$1}
    
    if command -v $cmd >/dev/null 2>&1; then
        echo -e "✓ ${GREEN}$name${NC}: Available ($(which $cmd))"
        return 0
    else
        echo -e "✗ ${RED}$name${NC}: Not found"
        return 1
    fi
}

# Function to check version
check_version() {
    local cmd=$1
    local name=$2
    local min_version=$3
    
    if command -v $cmd >/dev/null 2>&1; then
        local version=$($cmd --version 2>/dev/null | head -1)
        echo -e "✓ ${GREEN}$name${NC}: $version"
    else
        echo -e "✗ ${RED}$name${NC}: Not available"
    fi
}

echo -e "${YELLOW}=== System Requirements Check ===${NC}"
echo "CPU Cores: $(nproc)"
echo "Total RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Available Disk: $(df -h / | awk 'NR==2 {print $4}')"
echo ""

echo -e "${YELLOW}=== Essential Tools Check ===${NC}"
check_command python3 "Python 3"
check_command pip3 "pip3"
check_command ansible "Ansible"
check_command git "Git"
check_command curl "curl"
check_command ssh "SSH Client"
check_command openssl "OpenSSL"
echo ""

echo -e "${YELLOW}=== Version Information ===${NC}"
check_version python3 "Python" "3.8"
check_version ansible "Ansible" "2.9"
check_version git "Git" "2.25"
echo ""

echo -e "${YELLOW}=== Python Environment Check ===${NC}"
if python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)" 2>/dev/null; then
    echo -e "✓ ${GREEN}Python version${NC}: Compatible (3.8+)"
else
    echo -e "✗ ${RED}Python version${NC}: Incompatible (needs 3.8+)"
fi

# Check pip packages
for pkg in virtualenv setuptools wheel; do
    if python3 -c "import $pkg" 2>/dev/null; then
        echo -e "✓ ${GREEN}Python $pkg${NC}: Available"
    else
        echo -e "✗ ${RED}Python $pkg${NC}: Not installed"
    fi
done
echo ""

echo -e "${YELLOW}=== Ansible Collections Check ===${NC}"
collections=("cisco.dnac" "cisco.ios" "community.general" "ansible.posix")
for collection in "${collections[@]}"; do
    if ansible-galaxy collection list | grep -q "$collection"; then
        echo -e "✓ ${GREEN}$collection${NC}: Installed"
    else
        echo -e "✗ ${RED}$collection${NC}: Not installed"
    fi
done
echo ""

echo -e "${YELLOW}=== Network Tools Check ===${NC}"
check_command ping "ping"
check_command nslookup "nslookup"
check_command netstat "netstat"
check_command ss "ss"
check_command tcpdump "tcpdump"
echo ""

echo -e "${YELLOW}=== SSH Configuration Check ===${NC}"
if [ -f ~/.ssh/id_rsa ]; then
    echo -e "✓ ${GREEN}SSH Private Key${NC}: Present"
else
    echo -e "✗ ${RED}SSH Private Key${NC}: Missing"
fi

if [ -f ~/.ssh/id_rsa.pub ]; then
    echo -e "✓ ${GREEN}SSH Public Key${NC}: Present"
else
    echo -e "✗ ${RED}SSH Public Key${NC}: Missing"
fi

if [ -f ~/.ssh/config ]; then
    echo -e "✓ ${GREEN}SSH Config${NC}: Present"
else
    echo -e "✗ ${RED}SSH Config${NC}: Missing"
fi
echo ""

echo -e "${YELLOW}=== Network Connectivity Check ===${NC}"
# DNS Test
if nslookup google.com >/dev/null 2>&1; then
    echo -e "✓ ${GREEN}DNS Resolution${NC}: Working"
else
    echo -e "✗ ${RED}DNS Resolution${NC}: Failed"
fi

# Internet connectivity
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo -e "✓ ${GREEN}Internet Connectivity${NC}: Working"
else
    echo -e "✗ ${RED}Internet Connectivity${NC}: Failed"
fi

# HTTPS connectivity
if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    echo -e "✓ ${GREEN}HTTPS Connectivity${NC}: Working"
else
    echo -e "✗ ${RED}HTTPS Connectivity${NC}: Failed"
fi
echo ""

echo -e "${YELLOW}=== Ansible Configuration Check ===${NC}"
if [ -f ~/.ansible.cfg ]; then
    echo -e "✓ ${GREEN}Ansible Config${NC}: Present"
else
    echo -e "✗ ${RED}Ansible Config${NC}: Missing"
fi

# Test Ansible basic functionality
if ansible localhost -m ping >/dev/null 2>&1; then
    echo -e "✓ ${GREEN}Ansible Functionality${NC}: Working"
else
    echo -e "✗ ${RED}Ansible Functionality${NC}: Failed"
fi
echo ""

echo -e "${BLUE}=== Validation Complete ===${NC}"
echo "System ready for Cisco Catalyst Center PNP deployment automation."
EOF

chmod +x ~/validate_environment.sh
```

### Step 2: Run Environment Validation

```bash
# Execute validation script
~/validate_environment.sh

# Run network connectivity test
~/test_network.sh

# Test Ansible basic functionality
ansible localhost -m ping
ansible --version
ansible-galaxy collection list | head -10
```

---

## Post-Setup Configuration

### Step 1: Create Working Directories

```bash
# Create project workspace
mkdir -p ~/ansible-projects/{inventories,playbooks,configs,logs,scripts}
mkdir -p ~/ansible-projects/inventories/{group_vars,host_vars}

# Set proper permissions
chmod 755 ~/ansible-projects
chmod 755 ~/ansible-projects/*
```

### Step 2: Configure Environment Variables

```bash
# Add automation-specific environment variables
cat >> ~/.bashrc << 'EOF'

# Ansible and Network Automation Environment
export ANSIBLE_CONFIG=~/.ansible.cfg
export ANSIBLE_HOST_KEY_CHECKING=False
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Automation project shortcuts
alias ansible-projects='cd ~/ansible-projects'
alias validate-env='~/validate_environment.sh'
alias test-network='~/test_network.sh'
EOF

# Reload shell configuration
source ~/.bashrc
```

### Step 3: Create Project Template Structure

```bash
# Create example project structure
cd ~/ansible-projects

# Create example inventory template
cat > inventories/example_hosts.yml << 'EOF'
---
# Example inventory for Cisco Catalyst Center PNP automation
# Copy this file and update with your environment details

all:
  children:
    catalyst_center:
      hosts:
        dnac_primary:
          ansible_host: "192.168.1.100"     # Update with Catalyst Center IP
          ansible_user: "admin"              # Update with API username
          ansible_password: "your_password"  # Update with API password
          ansible_connection: local
          
    network_devices:
      hosts:
        device_001:
          serial_number: "FCH1234ABCD"      # Update with device serial
          hostname: "branch-router-01"      # Update with device hostname
          site_hierarchy: "Global/Region_01/Branch_01"  # Update site path
          device_type: "Cisco Catalyst 8000V"
          management_ip: "192.168.100.10"
          
  vars:
    # Global variables
    ansible_python_interpreter: "{{ ansible_playbook_python }}"
    dnac_verify: false
    dnac_debug: false
EOF

# Create example group variables
cat > inventories/group_vars/all.yml << 'EOF'
---
# Global variables for all hosts
ansible_connection: local
gather_facts: false

# Catalyst Center API settings
dnac_host: "{{ hostvars[groups['catalyst_center'][0]]['ansible_host'] }}"
dnac_username: "{{ hostvars[groups['catalyst_center'][0]]['ansible_user'] }}"
dnac_password: "{{ hostvars[groups['catalyst_center'][0]]['ansible_password'] }}"
dnac_verify: false
dnac_version: "3.1.0"
dnac_debug: false

# Default timeouts
api_timeout: 60
task_timeout: 300
pnp_timeout: 1800
EOF

echo "Project template structure created successfully."
```

---

## Troubleshooting Common Issues

### Issue 1: Python Version Compatibility

**Problem:** Python version too old or multiple Python versions installed

**Solution:**
```bash
# Check available Python versions
ls /usr/bin/python*

# Create symlink if needed (Ubuntu 20.04+)
sudo apt install -y python-is-python3

# Verify Python 3 is default
python --version
which python
```

### Issue 2: Ansible Collection Installation Failures

**Problem:** Ansible collections fail to install due to permissions or network

**Solution:**
```bash
# Install collections with force flag
ansible-galaxy collection install cisco.dnac --force --no-deps

# Install from requirements file
cat > requirements.yml << 'EOF'
collections:
  - cisco.dnac
  - cisco.ios
  - community.general
  - ansible.posix
EOF

ansible-galaxy collection install -r requirements.yml --force
```

### Issue 3: SSH Key Permission Issues

**Problem:** SSH keys have incorrect permissions

**Solution:**
```bash
# Fix SSH directory and file permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/config
```

### Issue 4: Network Connectivity Issues

**Problem:** Cannot reach external resources or Catalyst Center

**Solution:**
```bash
# Check network configuration
ip route show
cat /etc/resolv.conf

# Test specific connectivity
ping -c 4 8.8.8.8
nslookup google.com
curl -v https://github.com

# Check firewall rules
sudo ufw status
sudo iptables -L
```

### Issue 5: Package Installation Failures

**Problem:** APT packages fail to install

**Solution:**
```bash
# Update package cache and fix broken packages
sudo apt update
sudo apt --fix-broken install
sudo dpkg --configure -a

# Clean package cache
sudo apt autoremove
sudo apt autoclean

# Retry installation
sudo apt update && sudo apt upgrade -y
```

---

## Next Steps

After completing this preparation procedure:

1. **Clone Repository:** Get the CCC PNP C8000V automation project:
   ```bash
   cd ~/ansible-projects
   git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git
   cd ccc-pnp-c8000v
   ```

2. **Run Setup Script:** Execute the automated environment setup:
   ```bash
   ./setup_environment.sh
   ```

3. **Configure Project:** Update inventory files with your environment details
4. **Test Connectivity:** Verify network connectivity to your Catalyst Center
5. **Execute Deployment:** Run the PNP automation playbooks

Your Ubuntu admin PC is now fully prepared for Cisco Catalyst Center PNP deployment automation.

---

**Environment Preparation Complete**

The system is now ready to support Cisco Catalyst Center PNP automation workflows with all required tools, configurations, and dependencies properly installed and configured.