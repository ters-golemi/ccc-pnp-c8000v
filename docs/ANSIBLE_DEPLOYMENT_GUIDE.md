# Complete Ansible Deployment Guide for Cisco Catalyst Center PNP

This comprehensive guide provides step-by-step instructions for deploying Cisco Catalyst 8000v routers using Ansible automation and Cisco Catalyst Center PNP functionality.

## Table of Contents

1. [Prerequisites and Environment Setup](#prerequisites-and-environment-setup)
2. [Ubuntu Client Machine Preparation](#ubuntu-client-machine-preparation)
3. [Ansible Installation and Configuration](#ansible-installation-and-configuration)
4. [Project Setup and Configuration](#project-setup-and-configuration)
5. [Catalyst Center Configuration](#catalyst-center-configuration)
6. [Inventory Configuration](#inventory-configuration)
7. [Playbook Execution](#playbook-execution)
8. [Monitoring and Validation](#monitoring-and-validation)
9. [Troubleshooting Common Issues](#troubleshooting-common-issues)
10. [Advanced Deployment Scenarios](#advanced-deployment-scenarios)

---

## Prerequisites and Environment Setup

### Network Infrastructure Requirements

Before beginning the deployment, ensure your network infrastructure meets these requirements:

**Network Topology:**
```
[Ubuntu Client] ----> [Management Network] ----> [Catalyst Center]
                                    |
                                    v
[DHCP Server] -----------------> [PNP Network] ----> [C8000v Devices]
```

**Required Network Components:**
- DHCP server with Option 43 configured
- DNS server (recommended)
- NTP server (recommended)
- Management network with Layer 3 connectivity
- PNP network for device onboarding

### Hardware Requirements

**Ubuntu Client Machine:**
- Minimum 2 CPU cores
- 4GB RAM minimum (8GB recommended)
- 20GB available disk space
- Network connectivity to Catalyst Center

**Cisco Catalyst Center:**
- Version 3.1.X or later
- API services enabled
- Appropriate licensing for managed devices

**Target Devices:**
- Cisco Catalyst 8000v routers
- Factory default configuration
- Network connectivity to PNP subnet

### Software Version Requirements

- Ubuntu 20.04 LTS or later
- Python 3.8 or higher
- Ansible 2.9 or higher
- Git 2.25 or higher

---

## Ubuntu Client Machine Preparation

### Step 1: System Update and Basic Packages

```bash
# Update package repositories
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y software-properties-common apt-transport-https ca-certificates gnupg lsb-release curl wget vim git
```

### Step 2: Python Environment Setup

```bash
# Install Python and pip
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Verify Python installation
python3 --version
pip3 --version

# Install Python development tools
sudo apt install -y build-essential libssl-dev libffi-dev python3-setuptools
```

### Step 3: Network Tools Installation

```bash
# Install network diagnostic tools
sudo apt install -y net-tools iputils-ping traceroute nmap tcpdump wireshark-common

# Install SSL/TLS tools
sudo apt install -y openssl ca-certificates-java
```

### Step 4: Security Configuration

```bash
# Generate SSH key pair (if not already present)
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -N "" -f ~/.ssh/id_rsa
fi

# Set proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

---

## Ansible Installation and Configuration

### Step 1: Install Ansible via APT

```bash
# Add Ansible official repository
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install -y ansible

# Verify installation
ansible --version
ansible-galaxy --version
```

### Step 2: Alternative Installation via pip (if needed)

```bash
# Create virtual environment
python3 -m venv ~/ansible-env
source ~/ansible-env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Ansible
pip install ansible

# Install additional Python packages for Cisco modules
pip install requests urllib3 dnspython netaddr jmespath
```

### Step 3: Configure Ansible Settings

```bash
# Create Ansible configuration directory
mkdir -p ~/.ansible/collections
mkdir -p ~/.ansible/roles

# Create global Ansible configuration
cat > ~/.ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory
host_key_checking = False
timeout = 30
forks = 10
log_path = ./ansible.log
retry_files_enabled = False
gathering = explicit

[inventory]
enable_plugins = host_list, script, auto, yaml, ini

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
EOF
```

### Step 4: Install Required Ansible Collections

```bash
# Install Cisco collections
ansible-galaxy collection install cisco.dnac
ansible-galaxy collection install cisco.ios

# Install community collections
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

# Verify installed collections
ansible-galaxy collection list
```

---

## Project Setup and Configuration

### Step 1: Clone Project Repository

```bash
# Create projects directory
mkdir -p ~/ansible-projects
cd ~/ansible-projects

# Clone the repository
git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git
cd ccc-pnp-c8000v

# Verify project structure
ls -la
```

### Step 2: Python Virtual Environment Setup

```bash
# Create project-specific virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create activation script
cat > activate_project.sh << 'EOF'
#!/bin/bash
cd ~/ansible-projects/ccc-pnp-c8000v
source venv/bin/activate
echo "Project environment activated"
echo "Current directory: $(pwd)"
echo "Python version: $(python --version)"
echo "Ansible version: $(ansible --version | head -1)"
EOF

chmod +x activate_project.sh
```

### Step 3: Verify Project Dependencies

```bash
# Check Python packages
pip list | grep -E "(requests|urllib3|ansible|dnspython)"

# Test Ansible collections
ansible-doc cisco.dnac.device_info

# Verify project files
find . -name "*.yml" -o -name "*.yaml" | head -10
```

---

## Catalyst Center Configuration

### Step 1: Access Catalyst Center Web Interface

1. Open web browser and navigate to Catalyst Center
2. Login with administrative credentials
3. Navigate to **System > Settings > External Services**
4. Verify REST API is enabled

### Step 2: Configure Network Settings

```bash
# Example network configuration steps:
```

**Navigate to: Design > Network Settings**

1. **IP Pools Configuration:**
   - Create IP pool for PNP devices: `192.168.100.0/24`
   - Set DHCP server: `192.168.1.10`
   - Configure DNS servers: `8.8.8.8, 8.8.4.4`

2. **Device Credentials:**
   - CLI Username: `admin`
   - CLI Password: `Cisco123!`
   - Enable Password: `Cisco123!`
   - SNMP Read Community: `public`
   - SNMP Write Community: `private`

3. **DHCP Server Configuration:**
   ```bash
   # DHCP server configuration (on DHCP server)
   subnet 192.168.100.0 netmask 255.255.255.0 {
       range 192.168.100.10 192.168.100.100;
       option routers 192.168.100.1;
       option domain-name-servers 8.8.8.8, 8.8.4.4;
       option domain-name "pnp.local";
       option dhcp-parameter-request-list 1,3,6,43,150;
       option option-43 "5A1N;B2;K4;I192.168.1.100;J80";
   }
   ```

### Step 3: Site Hierarchy Configuration

**Navigate to: Design > Network Hierarchy**

1. Create site hierarchy:
   ```
   Global
   └── Region_01
       └── Building_01
           └── Floor_01
   ```

2. Assign network settings to each site level

### Step 4: Network Profile Creation

**Navigate to: Design > Network Profiles**

1. Create new profile for C8000v devices
2. Configure day-0 template:
   ```
   hostname ${hostname}
   !
   interface GigabitEthernet0/0/0
    ip address dhcp
    no shutdown
   !
   interface GigabitEthernet0/0/1
    ip address ${mgmt_ip} ${mgmt_mask}
    no shutdown
   !
   ip route 0.0.0.0 0.0.0.0 ${gateway}
   !
   line vty 0 4
    login local
    transport input ssh
   !
   ```

---

## Inventory Configuration

### Step 1: Create Inventory Structure

```bash
# Create inventory directory structure
mkdir -p inventory/{group_vars,host_vars}

# Create main inventory file
cat > inventory/hosts.yml << 'EOF'
---
all:
  children:
    dnac:
      hosts:
        catalyst_center:
          ansible_host: "192.168.1.100"
          ansible_user: "admin"
          ansible_password: "Cisco123!"
          ansible_connection: local
    
    devices:
      hosts:
        v8000-1:
          ansible_host: "192.168.1.10"
          ansible_user: "admin"
          ansible_password: "Cisco123!"
          serial_number: "9ABCDEFGHIJ"
          hostname: "v8000-router-01"
          site: "Global/Region_01/Building_01/Floor_01"
          
        v8000-2:
          ansible_host: "192.168.1.11"
          ansible_user: "admin"
          ansible_password: "Cisco123!"
          serial_number: "9KLMNOPQRST"
          hostname: "v8000-router-02"
          site: "Global/Region_01/Building_01/Floor_01"
          device_type: "Cisco Catalyst 8000V"
          management_ip: "192.168.100.11"
          management_mask: "255.255.255.0"
          gateway: "192.168.100.1"

    pnp_devices:
      hosts:
        v8000-2:
EOF
```

### Step 2: Configure Group Variables

```bash
# Create group variables for all devices
cat > inventory/group_vars/all.yml << 'EOF'
---
# Global variables for all devices
ansible_connection: local
ansible_python_interpreter: "{{ ansible_playbook_python }}"

# Catalyst Center configuration
dnac_host: "{{ hostvars['catalyst_center']['ansible_host'] }}"
dnac_username: "{{ hostvars['catalyst_center']['ansible_user'] }}"
dnac_password: "{{ hostvars['catalyst_center']['ansible_password'] }}"
dnac_verify: false
dnac_version: "3.1.0"
dnac_debug: false

# PNP configuration
pnp_timeout: 1800  # 30 minutes
pnp_retry_count: 5
pnp_retry_delay: 60

# Device credentials
device_username: "admin"
device_password: "Cisco123!"
enable_password: "Cisco123!"

# Network settings
dns_servers:
  - "8.8.8.8"
  - "8.8.4.4"
ntp_servers:
  - "pool.ntp.org"
EOF
```

### Step 3: Configure Device-Specific Variables

```bash
# Create host-specific variables
cat > inventory/host_vars/v8000-2.yml << 'EOF'
---
# Device-specific configuration for v8000-2
device_model: "C8000V"
device_family: "Routers"
device_series: "Cisco Catalyst 8000 Series"

# Network configuration
interfaces:
  GigabitEthernet0/0/0:
    description: "WAN Interface"
    ip_address: "dhcp"
  GigabitEthernet0/0/1:
    description: "LAN Interface"
    ip_address: "{{ management_ip }}"
    subnet_mask: "{{ management_mask }}"

# Day-0 configuration template
day0_template: |
  hostname {{ hostname }}
  !
  interface GigabitEthernet0/0/0
   description WAN Interface
   ip address dhcp
   no shutdown
  !
  interface GigabitEthernet0/0/1
   description LAN Interface
   ip address {{ management_ip }} {{ management_mask }}
   no shutdown
  !
  ip route 0.0.0.0 0.0.0.0 {{ gateway }}
  !
  username {{ device_username }} privilege 15 password {{ device_password }}
  !
  line vty 0 4
   login local
   transport input ssh
  !
  ip ssh version 2
  !
EOF
```

---

## Playbook Execution

### Step 1: Pre-Flight Validation

```bash
# Activate project environment
source venv/bin/activate

# Test Ansible configuration
ansible --version
ansible-inventory --list -i inventory/hosts.yml

# Test connectivity to Catalyst Center
ansible catalyst_center -i inventory/hosts.yml -m ping

# Validate inventory syntax
ansible-playbook --syntax-check ansible/playbooks/pnp_onboard_device.yml -i inventory/hosts.yml
```

### Step 2: Execute PNP Device Check

```bash
# Check current PNP device status
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_check_status.yml -v

# Expected output should show device status in Catalyst Center
```

### Step 3: Execute Device Claiming

```bash
# Claim devices in Catalyst Center
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_claim_device.yml -v --limit v8000-2

# Monitor output for successful claiming
```

### Step 4: Execute Complete PNP Onboarding

```bash
# Run complete onboarding workflow
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml -v

# Add extra verbosity for debugging if needed
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml -vvv
```

### Step 5: Execute Device Provisioning

```bash
# Provision devices with full configuration
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_provision_device.yml -v --limit v8000-2

# Check provisioning status
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_check_status.yml -v --limit v8000-2
```

---

## Monitoring and Validation

### Step 1: Real-time Monitoring Setup

```bash
# Create monitoring script
cat > monitor_pnp.sh << 'EOF'
#!/bin/bash

echo "PNP Onboarding Monitor"
echo "====================="
echo "Starting monitoring at $(date)"

while true; do
    clear
    echo "PNP Device Status - $(date)"
    echo "=================================="
    
    # Run status check playbook
    ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_check_status.yml --limit v8000-2 2>/dev/null | grep -E "(TASK|ok:|failed:|changed:|PLAY RECAP)"
    
    echo "=================================="
    echo "Refreshing in 30 seconds... (Ctrl+C to stop)"
    sleep 30
done
EOF

chmod +x monitor_pnp.sh
```

### Step 2: Validation Checklist

Create a validation playbook:

```bash
cat > ansible/playbooks/validate_deployment.yml << 'EOF'
---
- name: Validate PNP Deployment
  hosts: localhost
  gather_facts: no
  
  vars:
    dnac_host: "{{ hostvars['catalyst_center']['ansible_host'] }}"
    dnac_username: "{{ hostvars['catalyst_center']['ansible_user'] }}"
    dnac_password: "{{ hostvars['catalyst_center']['ansible_password'] }}"
    device_serial: "{{ hostvars['v8000-2']['serial_number'] }}"
  
  tasks:
    - name: Get authentication token
      uri:
        url: "https://{{ dnac_host }}/dna/system/api/v1/auth/token"
        method: POST
        user: "{{ dnac_username }}"
        password: "{{ dnac_password }}"
        headers:
          Content-Type: "application/json"
        validate_certs: false
        status_code: 200
      register: auth_response
    
    - name: Get device information
      uri:
        url: "https://{{ dnac_host }}/dna/intent/api/v1/network-device/{{ device_serial }}"
        method: GET
        headers:
          X-Auth-Token: "{{ auth_response.json.Token }}"
        validate_certs: false
      register: device_info
    
    - name: Display validation results
      debug:
        msg:
          - "==============================="
          - "DEPLOYMENT VALIDATION RESULTS"
          - "==============================="
          - "Device Serial: {{ device_serial }}"
          - "Device Status: {{ device_info.json.response.reachabilityStatus | default('Unknown') }}"
          - "Management IP: {{ device_info.json.response.managementIpAddress | default('Not Assigned') }}"
          - "Site: {{ device_info.json.response.location | default('Not Assigned') }}"
          - "Last Updated: {{ device_info.json.response.lastUpdated | default('Unknown') }}"
          - "==============================="
    
    - name: Validate device reachability
      uri:
        url: "https://{{ dnac_host }}/dna/intent/api/v1/device-health"
        method: GET
        headers:
          X-Auth-Token: "{{ auth_response.json.Token }}"
        validate_certs: false
      register: device_health
    
    - name: Check device health status
      debug:
        msg: "Device Health Score: {{ (device_health.json.response | selectattr('id', 'equalto', device_info.json.response.id) | first).healthScore | default('Unknown') }}"
EOF
```

### Step 3: Execute Validation

```bash
# Run validation playbook
ansible-playbook -i inventory/hosts.yml ansible/playbooks/validate_deployment.yml -v
```

---

## Troubleshooting Common Issues

### Issue 1: Authentication Failures

**Symptoms:**
- HTTP 401 errors
- "Authentication failed" messages
- Token-related errors

**Solutions:**
```bash
# Test manual authentication
curl -k -X POST "https://192.168.1.100/dna/system/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -u "admin:Cisco123!"

# Verify credentials in inventory
ansible-vault decrypt inventory/group_vars/all.yml  # if encrypted

# Test with debug mode
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_check_status.yml -vvv
```

### Issue 2: Device Not Found in PNP

**Symptoms:**
- "Device not found" errors
- Serial number mismatches
- Empty device list responses

**Solutions:**
```bash
# Verify device serial number
show version | include Serial
show license udi

# Check device in web interface
# Navigate to Provision > Plug and Play > Devices

# Manual device addition if needed
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_add_device.yml -v
```

### Issue 3: Network Connectivity Issues

**Symptoms:**
- Connection timeouts
- DNS resolution failures
- DHCP option 43 issues

**Solutions:**
```bash
# Test network connectivity
ping 192.168.1.100  # Catalyst Center IP
nslookup catalyst-center.domain.com

# Verify DHCP configuration
sudo tcpdump -i eth0 port 67 or port 68

# Check routing
ip route show
traceroute 192.168.1.100
```

### Issue 4: Playbook Execution Errors

**Symptoms:**
- Ansible module errors
- Variable undefined errors
- Task failures

**Solutions:**
```bash
# Check Ansible syntax
ansible-playbook --syntax-check ansible/playbooks/pnp_onboard_device.yml

# Validate inventory
ansible-inventory --list -i inventory/hosts.yml

# Run with increased verbosity
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml -vvv --check

# Check specific task
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml --start-at-task="Check if device exists in PNP"
```

---

## Advanced Deployment Scenarios

### Scenario 1: Batch Device Onboarding

```bash
# Create batch inventory for multiple devices
cat > inventory/batch_devices.yml << 'EOF'
---
all:
  children:
    pnp_devices:
      hosts:
        device_001:
          serial_number: "9ABCDEF001"
          hostname: "branch-router-001"
          site: "Global/Region_01/Branch_001"
        device_002:
          serial_number: "9ABCDEF002"
          hostname: "branch-router-002"
          site: "Global/Region_01/Branch_002"
        device_003:
          serial_number: "9ABCDEF003"
          hostname: "branch-router-003"
          site: "Global/Region_01/Branch_003"
EOF

# Execute batch onboarding
ansible-playbook -i inventory/batch_devices.yml ansible/playbooks/pnp_onboard_device.yml --forks 3
```

### Scenario 2: Staged Deployment with Rollback

```bash
# Create staged deployment playbook
cat > ansible/playbooks/staged_deployment.yml << 'EOF'
---
- name: Staged PNP Deployment with Rollback
  hosts: localhost
  gather_facts: no
  serial: 1
  
  tasks:
    - name: Stage 1 - Device Discovery and Claiming
      include_tasks: pnp_claim_device.yml
      
    - name: Stage 2 - Pre-deployment Validation
      include_tasks: validate_prerequisites.yml
      
    - name: Stage 3 - Device Onboarding
      include_tasks: pnp_onboard_device.yml
      register: onboarding_result
      
    - name: Stage 4 - Post-deployment Validation
      include_tasks: validate_deployment.yml
      register: validation_result
      
    - name: Rollback if validation fails
      include_tasks: rollback_deployment.yml
      when: validation_result.failed is defined and validation_result.failed
EOF
```

### Scenario 3: Integration with CI/CD Pipeline

```bash
# Create Jenkins pipeline script
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        PYTHONUNBUFFERED = '1'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Environment') {
            steps {
                sh '''
                    python3 -m venv venv
                    source venv/bin/activate
                    pip install -r requirements.txt
                '''
            }
        }
        
        stage('Validate Configuration') {
            steps {
                sh '''
                    source venv/bin/activate
                    ansible-playbook --syntax-check ansible/playbooks/pnp_onboard_device.yml
                    ansible-inventory --list -i inventory/hosts.yml
                '''
            }
        }
        
        stage('Execute PNP Onboarding') {
            steps {
                sh '''
                    source venv/bin/activate
                    ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml
                '''
            }
        }
        
        stage('Validate Deployment') {
            steps {
                sh '''
                    source venv/bin/activate
                    ansible-playbook -i inventory/hosts.yml ansible/playbooks/validate_deployment.yml
                '''
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'ansible.log', allowEmptyArchive: true
            cleanWs()
        }
        failure {
            emailext to: 'network-team@company.com',
                     subject: 'PNP Deployment Failed: ${BUILD_TAG}',
                     body: 'The PNP deployment pipeline has failed. Please check the logs.'
        }
    }
}
EOF
```

This comprehensive guide provides complete step-by-step instructions for deploying Cisco Catalyst 8000v routers using Ansible automation from an Ubuntu client machine. The guide includes all necessary prerequisites, configuration steps, execution procedures, and troubleshooting information needed for successful deployment.