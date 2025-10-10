# Cisco Catalyst Center PNP Automation for C8000v

This project automates the Plug and Play (PNP) onboarding process for Cisco Catalyst 8000v routers using Ansible, Python scripts, and Cisco Catalyst Center 3.1.X API.

## Topology

```
DNAC (Cisco Catalyst Center) ----> C1Kv ----> v8000-1 ----> v8000-2
```

The automation focuses on onboarding the `v8000-2` router through the PNP process.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Ubuntu Workstation Setup](#ubuntu-workstation-setup)
- [Cisco Catalyst Center Setup](#cisco-catalyst-center-setup)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Workflow](#workflow)
- [Troubleshooting](#troubleshooting)

## Additional Documentation

- **[Ubuntu Admin PC Setup Guide](docs/UBUNTU_ADMIN_PC_SETUP.md)** - Complete Ubuntu workstation preparation for PNP automation
- **[Complete Ansible Deployment Guide](docs/ANSIBLE_DEPLOYMENT_GUIDE.md)** - Comprehensive step-by-step deployment procedures
- **[Quick Start Guide](QUICK_START.md)** - Get started in under 10 minutes
- **[Workflow Details](docs/WORKFLOW.md)** - Detailed PNP process explanation
- **[API Reference](docs/API_REFERENCE.md)** - Catalyst Center API documentation
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Prerequisites

### Hardware Requirements
- Ubuntu workstation (20.04 LTS or later recommended)
- Cisco Catalyst Center 3.1.X deployed
- Network connectivity to Catalyst Center
- C1Kv and v8000-1 routers configured and reachable
- v8000-2 router ready for PNP onboarding

### Software Requirements
- Python 3.8 or higher
- Ansible 2.9 or higher
- Git
- Access to Cisco Catalyst Center with API credentials

### Network Requirements
- Network connectivity between Ubuntu workstation and Catalyst Center
- PNP subnet configured on Catalyst Center
- DHCP server configured for PNP devices
- DNS resolution (if using hostnames)

## Ubuntu Workstation Setup

For detailed Ubuntu workstation preparation instructions, see the **[Ubuntu Admin PC Setup Guide](docs/UBUNTU_ADMIN_PC_SETUP.md)**.

### Quick Setup Summary

1. **System Requirements:** Ubuntu 20.04 LTS or later, 4GB RAM, 20GB storage
2. **Update System:** `sudo apt update && sudo apt upgrade -y`
3. **Install Python:** `sudo apt install -y python3 python3-pip python3-venv`
4. **Install Ansible:** `sudo add-apt-repository ppa:ansible/ansible && sudo apt install ansible`
5. **Install Collections:** `ansible-galaxy collection install cisco.dnac cisco.ios`
6. **Clone Repository:** `git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git`
7. **Run Setup:** `cd ccc-pnp-c8000v && ./setup_environment.sh`

> 📖 **For complete step-by-step instructions including network tools, security configuration, and troubleshooting, refer to the [Ubuntu Admin PC Setup Guide](docs/UBUNTU_ADMIN_PC_SETUP.md)**

## Cisco Catalyst Center Setup

### 1. PNP Prerequisites on Catalyst Center

Before running the automation, ensure the following are configured on Cisco Catalyst Center:

#### A. Network Settings
- Configure IP address pools for PNP devices
- Set up DHCP server with option 43 pointing to Catalyst Center
- Configure DNS settings

#### B. Device Credentials
Navigate to: **Design > Network Settings > Device Credentials**
- Add CLI credentials for device access
- Add SNMP credentials (SNMPv2c or SNMPv3)
- Add HTTP(S) credentials if needed

#### C. Site Hierarchy
Navigate to: **Design > Network Hierarchy**
- Create appropriate site hierarchy
- Example: Global > Region > Building > Floor

#### D. Network Profile
Navigate to: **Design > Network Profiles**
- Create a network profile for C8000v devices
- Assign day-0 templates
- Configure network settings

#### E. PNP Settings
Navigate to: **Provision > Plug and Play**
- Enable PNP services
- Configure PNP server profile
- Set up virtual account (if using Smart Licensing)

### 2. API Access Setup

#### A. Enable API Access
Navigate to: **System > Settings > External Services**
- Ensure REST API is enabled
- Note the Catalyst Center IP/hostname

#### B. Create API User
Navigate to: **System > Users**
- Create a user with appropriate permissions
- Assign role: Network Admin or Super Admin
- Note username and password for API access

#### C. Verify API Access
Test API connectivity:
```bash
curl -k -X POST "https://<catalyst-center-ip>/dna/system/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'username:password' | base64)"
```

### 3. Day-0 Template Configuration

Create a Day-0 configuration template for the v8000-2 router:

Navigate to: **Tools > Template Editor**
- Click "Add Template"
- Select device type: Catalyst 8000v
- Create configuration template with variables

Example template:
```
hostname $hostname
!
interface GigabitEthernet1
 description WAN Interface
 ip address $wan_ip $wan_mask
 no shutdown
!
interface GigabitEthernet2
 description LAN Interface
 ip address $lan_ip $lan_mask
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 $gateway
!
```

## Installation

### Method 1: Automated Setup (Recommended)

Use the automated setup script for complete environment preparation:

```bash
# Clone repository
git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git
cd ccc-pnp-c8000v

# Run automated setup script
./setup_environment.sh
```

The setup script automatically handles:
- Python virtual environment creation and activation
- Installation of all required dependencies and Ansible collections
- Example inventory structure creation
- Environment validation and verification
- Guidance for next steps

### Method 2: Manual Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git
cd ccc-pnp-c8000v
```

### 2. Create Python Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 4. Verify Installation

```bash
# Check Python packages
pip list

# Check Ansible modules
ansible-galaxy collection list
```

## Configuration

### 1. Configure Credentials

Copy the example configuration file:
```bash
cp configs/config.example.yml configs/config.yml
```

Edit `configs/config.yml` with your environment details:
```yaml
catalyst_center:
  host: "catalyst-center.example.com"
  username: "admin"
  password: "your_password"
  verify_ssl: false
  version: "3.1.0"

device:
  serial_number: "FCH1234ABCD"
  hostname: "v8000-2"
  site: "Global/Region/Building/Floor"
  device_type: "Cisco Catalyst 8000V"
  
network:
  wan_interface:
    ip: "192.168.1.10"
    mask: "255.255.255.0"
    gateway: "192.168.1.1"
  lan_interface:
    ip: "10.0.0.1"
    mask: "255.255.255.0"
```

### 2. Configure Ansible Inventory

Edit `ansible/inventory/hosts.yml`:
```yaml
all:
  children:
    catalyst_center:
      hosts:
        dnac:
          ansible_host: catalyst-center.example.com
          ansible_user: admin
          ansible_password: your_password
    
    pnp_devices:
      hosts:
        v8000-2:
          serial_number: FCH1234ABCD
          hostname: v8000-2
          site: Global/Region/Building/Floor
```

### 3. Environment Variables (Optional)

Create a `.env` file for sensitive information:
```bash
export CATALYST_CENTER_HOST="catalyst-center.example.com"
export CATALYST_CENTER_USERNAME="admin"
export CATALYST_CENTER_PASSWORD="your_password"
export DEVICE_SERIAL="FCH1234ABCD"
```

Load environment variables:
```bash
source .env
```

## Usage

### Complete Step-by-Step Deployment Process

#### Prerequisites Validation

1. **Environment Setup Verification**
```bash
# Activate project environment
source venv/bin/activate

# Verify connectivity to Catalyst Center
ansible catalyst_center -i inventory/hosts.yml -m ping

# Validate inventory configuration
ansible-inventory --list -i inventory/hosts.yml | head -20

# Test playbook syntax
ansible-playbook --syntax-check ansible/playbooks/pnp_onboard_device.yml -i inventory/hosts.yml
```

#### Method 1: Complete Ansible Automation Workflow

2. **Execute Pre-Deployment Checks**
```bash
# Check current device status in Catalyst Center
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_check_status.yml -v

# Verify network prerequisites
ansible-playbook -i inventory/hosts.yml ansible/playbooks/validate_prerequisites.yml -v
```

3. **Device Claiming and Registration**
```bash
# Claim device in Catalyst Center PNP database
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_claim_device.yml -v

# Verify device is properly claimed
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_check_status.yml -v
```

4. **Complete PNP Onboarding Process**
```bash
# Execute full onboarding workflow
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml -v

# Monitor with detailed logging if needed
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml -vvv
```

5. **Device Provisioning and Final Configuration**
```bash
# Apply final device configuration and site assignment
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_provision_device.yml -v

# Validate successful provisioning
ansible-playbook -i inventory/hosts.yml ansible/playbooks/validate_deployment.yml -v
```

#### Method 2: Python Script Automation

6. **Alternative Python-based Approach**
```bash
# Configure environment variables
export DNAC_HOST="192.168.1.100"
export DNAC_USERNAME="admin"
export DNAC_PASSWORD="Cisco123!"

# Execute device claiming
python3 scripts/pnp_claim_device.py --config configs/config.yml --serial "9ABCDEFGHIJ"

# Monitor onboarding progress
python3 scripts/pnp_monitor.py --config configs/config.yml --serial "9ABCDEFGHIJ" --interval 30

# Complete device provisioning
python3 scripts/pnp_provision.py --config configs/config.yml --serial "9ABCDEFGHIJ"
```

#### Advanced Usage Scenarios

7. **Batch Processing Multiple Devices**
```bash
# Process multiple devices with controlled parallelism
ansible-playbook -i inventory/batch_hosts.yml ansible/playbooks/pnp_onboard_device.yml --forks 3

# Target specific device groups
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml --limit branch_routers
```

8. **Selective Task Execution**
```bash
# Start from specific task (resume partial deployment)
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml --start-at-task="Provision device configuration"

# Execute only specific task tags
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml --tags "claim,configure"

# Skip specific tasks
ansible-playbook -i inventory/hosts.yml ansible/playbooks/pnp_onboard_device.yml --skip-tags "validation"
```

9. **Monitoring and Troubleshooting**
```bash
# Real-time monitoring (if monitoring script exists)
./scripts/monitor_pnp.sh

# Check deployment logs
tail -f ansible.log

# Generate deployment report
ansible-playbook -i inventory/hosts.yml ansible/playbooks/generate_deployment_report.yml
```

For detailed deployment procedures, see: [Complete Ansible Deployment Guide](docs/ANSIBLE_DEPLOYMENT_GUIDE.md)

### Method 3: Using the Complete Automation Script

```bash
./scripts/automate_pnp.sh FCH1234ABCD
```

## Project Structure

```
ccc-pnp-c8000v/
├── README.md                          # This file
├── requirements.txt                   # Python dependencies
├── .gitignore                        # Git ignore file
│
├── configs/                          # Configuration files
│   ├── config.example.yml           # Example configuration
│   └── config.yml                   # Your configuration (not committed)
│
├── scripts/                          # Python automation scripts
│   ├── pnp_claim_device.py          # Claim device to PNP
│   ├── pnp_monitor.py               # Monitor PNP status
│   ├── pnp_provision.py             # Provision device
│   ├── catalyst_center_api.py       # API wrapper class
│   └── automate_pnp.sh              # Complete automation wrapper
│
├── ansible/                          # Ansible automation
│   ├── inventory/                   # Inventory files
│   │   ├── hosts.yml               # Inventory definition
│   │   └── group_vars/             # Group variables
│   │       └── all.yml             # Variables for all groups
│   │
│   ├── playbooks/                   # Ansible playbooks
│   │   ├── pnp_onboard_device.yml  # Complete onboarding workflow
│   │   ├── pnp_claim_device.yml    # Claim device
│   │   ├── pnp_check_status.yml    # Check status
│   │   └── pnp_provision_device.yml # Provision device
│   │
│   └── ansible.cfg                  # Ansible configuration
│
└── docs/                            # Additional documentation
    ├── API_REFERENCE.md            # API reference
    ├── TROUBLESHOOTING.md          # Troubleshooting guide
    └── WORKFLOW.md                 # Detailed workflow documentation
```

## Workflow

The PNP onboarding process follows these steps:

### 1. Pre-Discovery Phase
- Device powers on with factory default configuration
- Device obtains IP address via DHCP
- DHCP Option 43 or DNS lookup directs device to Catalyst Center

### 2. Discovery Phase
- Device contacts Catalyst Center PNP service
- Device sends device info (serial number, model, etc.)
- Catalyst Center authenticates the device

### 3. Claim Phase (Automated by this project)
- Script/playbook claims the device in Catalyst Center
- Assigns device to appropriate site
- Links device to configuration template
- Sets device parameters (hostname, IP, etc.)

### 4. Provisioning Phase
- Catalyst Center pushes Day-0 configuration to device
- Device applies configuration and reloads
- Device rejoins Catalyst Center with new configuration

### 5. Post-Provisioning
- Device shows as "Provisioned" in Catalyst Center
- Device is ready for Day-N configuration
- Device appears in device inventory

## Troubleshooting

### Common Issues

#### 1. Device Not Discovered
**Symptoms**: Device doesn't appear in PNP list

**Solutions**:
- Verify DHCP Option 43 is configured correctly
- Check network connectivity between device and Catalyst Center
- Verify PNP service is enabled on Catalyst Center
- Check device is in factory reset state

```bash
# Check PNP devices
python3 scripts/pnp_monitor.py --config configs/config.yml --list-all
```

#### 2. Authentication Failures
**Symptoms**: API calls return 401 Unauthorized

**Solutions**:
- Verify Catalyst Center credentials in config.yml
- Check user has appropriate permissions
- Regenerate API token

```bash
# Test API connectivity
curl -k -X POST "https://<catalyst-center-ip>/dna/system/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'username:password' | base64)"
```

#### 3. Claim Fails
**Symptoms**: Device claim operation fails

**Solutions**:
- Verify serial number is correct
- Check device is in "Unclaimed" state
- Verify site hierarchy exists
- Check template is valid and assigned

```bash
# Get device details
python3 scripts/pnp_monitor.py --config configs/config.yml --serial FCH1234ABCD
```

#### 4. Provisioning Fails
**Symptoms**: Device doesn't complete provisioning

**Solutions**:
- Check template syntax and variables
- Verify credentials are correct
- Check device connectivity during provisioning
- Review device logs

#### 5. SSL Certificate Errors
**Symptoms**: SSL verification errors

**Solutions**:
- Set `verify_ssl: false` in config.yml for testing
- Install Catalyst Center certificate on workstation
- Use IP address instead of hostname

### Debug Mode

Enable debug logging:

**Python Scripts**:
```bash
python3 scripts/pnp_claim_device.py --config configs/config.yml --debug
```

**Ansible**:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/pnp_onboard_device.yml -vvv
```

### Logs

Check logs for detailed information:
- Catalyst Center: System > Logs
- Device: `show logging` after provisioning
- Ansible: `/var/log/ansible.log` (if configured)
- Python: `logs/pnp_automation.log`

## Support and Contributing

### Getting Help
- Review documentation in `docs/` directory
- Check Cisco Catalyst Center documentation
- Review Ansible and Python documentation

### Contributing
Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is provided as-is for educational and automation purposes.

## References

- [Cisco Catalyst Center Documentation](https://www.cisco.com/c/en/us/support/cloud-systems-management/dna-center/series.html)
- [Cisco Catalyst Center API Guide](https://developer.cisco.com/docs/dna-center/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Python Requests Library](https://requests.readthedocs.io/)
- [Cisco C8000v Documentation](https://www.cisco.com/c/en/us/support/routers/catalyst-8000v-edge-software/series.html)

## Contact

For questions or issues, please open an issue on GitHub.