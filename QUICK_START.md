# Quick Start Guide

Get started with PNP automation in under 10 minutes using this step-by-step guide.

## Prerequisites Check

Before you begin, ensure you have:

- [ ] Ubuntu workstation (20.04 LTS or later)
- [ ] Network connectivity to Catalyst Center
- [ ] Catalyst Center 3.1.X credentials with API access
- [ ] Device serial number for target C8000v router
- [ ] Site hierarchy created in Catalyst Center
- [ ] DHCP server configured with Option 43
- [ ] Network profile configured for C8000v devices

## Quick Setup (Under 10 Minutes)

### 1. Install Required Tools (3 minutes)

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Python, Ansible, Git, and network tools
sudo apt install -y python3 python3-pip python3-venv ansible git curl wget net-tools

# Install additional development tools
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev

# Add Ansible repository for latest version
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Verify installations
echo "Python version: $(python3 --version)"
echo "Ansible version: $(ansible --version | head -1)"
echo "Git version: $(git --version)"
```

### 2. Clone Repository and Setup Environment (3 minutes)

```bash
# Create project directory
mkdir -p ~/ansible-projects
cd ~/ansible-projects

# Clone repository
git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git
cd ccc-pnp-c8000v

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip and install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install cisco.dnac cisco.ios community.general

# Verify setup
ansible --version
pip list | grep -E "(requests|urllib3|ansible)"
```

### 3. Configure Project Settings (2 minutes)

```bash
# Create inventory directory structure
mkdir -p inventory/{group_vars,host_vars}

# Copy example configuration
cp configs/config.example.yml configs/config.yml

# Create inventory file with your environment details
cat > inventory/hosts.yml << 'EOF'
---
all:
  children:
    dnac:
      hosts:
        catalyst_center:
          ansible_host: "YOUR_CATALYST_CENTER_IP"
          ansible_user: "YOUR_API_USERNAME"
          ansible_password: "YOUR_API_PASSWORD"
          ansible_connection: local
    
    devices:
      hosts:
        target_device:
          serial_number: "YOUR_DEVICE_SERIAL"
          hostname: "YOUR_DEVICE_HOSTNAME"
          site: "Global/YOUR_SITE_HIERARCHY"
          device_type: "Cisco Catalyst 8000V"
EOF

echo "Update the inventory/hosts.yml file with your actual environment details"

# Edit configuration with your details
vim configs/config.yml
```

**Minimum required settings:**
```yaml
catalyst_center:
  host: "your-catalyst-center.example.com"
  username: "admin"
  password: "your_password"
  verify_ssl: false

device:
  serial_number: "FCH1234ABCD"  # Your device serial
  hostname: "v8000-2"
  site: "Global/US/San_Jose/Floor1"  # Your site hierarchy
```

## Run Automation

### Option 1: Complete Automation (Recommended)

```bash
./scripts/automate_pnp.sh FCH1234ABCD
```

This runs the entire workflow automatically.

### Option 2: Step-by-Step

```bash
# Step 1: Check device status
python3 scripts/pnp_monitor.py --config configs/config.yml --list-all

# Step 2: Claim device
python3 scripts/pnp_claim_device.py --config configs/config.yml

# Step 3: Monitor provisioning
python3 scripts/pnp_monitor.py --config configs/config.yml --serial FCH1234ABCD --watch
```

### Option 3: Ansible

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/pnp_onboard_device.yml
```

## Expected Timeline

| Phase | Duration |
|-------|----------|
| Device boot and DHCP | 1-2 min |
| PNP discovery | 2-5 min |
| Device claim (automated) | 1-2 min |
| Configuration push | 5-10 min |
| Device reload | 2-3 min |
| **Total** | **11-22 min** |

## Verification

### Check Status

```bash
python3 scripts/pnp_monitor.py --config configs/config.yml --serial FCH1234ABCD
```

Expected output:
```
State: Provisioned
Hostname: v8000-2
```

### Verify in Catalyst Center

1. Navigate to **Provision > Inventory**
2. Search for device by serial number
3. Status should show: **Reachable** and **Managed**

### Access Device

```bash
ssh admin@<device-ip>
```

## Troubleshooting Quick Tips

### Device not found in PNP?
- Check DHCP Option 43 configuration
- Verify network connectivity
- Ensure device is factory reset

### Authentication failed?
- Verify credentials in `configs/config.yml`
- Check user has admin permissions
- Try re-generating API token

### Claim failed?
- Verify site exists in Catalyst Center
- Check device is in "Unclaimed" state
- Ensure serial number is correct

### Provisioning stuck?
- Check template syntax in Catalyst Center
- Verify device credentials are configured
- Monitor device console for errors

## Get Help

- **Detailed Documentation:** See [README.md](README.md)
- **API Reference:** See [docs/API_REFERENCE.md](docs/API_REFERENCE.md)
- **Troubleshooting:** See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Workflow Details:** See [docs/WORKFLOW.md](docs/WORKFLOW.md)

## Command Reference

### Python Scripts

```bash
# Monitor device
python3 scripts/pnp_monitor.py --config configs/config.yml --serial <SERIAL>

# Claim device
python3 scripts/pnp_claim_device.py --config configs/config.yml

# Check provisioning
python3 scripts/pnp_provision.py --config configs/config.yml

# Continuous monitoring
python3 scripts/pnp_monitor.py --config configs/config.yml --serial <SERIAL> --watch

# List all PNP devices
python3 scripts/pnp_monitor.py --config configs/config.yml --list-all

# Enable debug mode
python3 scripts/pnp_claim_device.py --config configs/config.yml --debug
```

### Ansible Playbooks

```bash
cd ansible

# Complete workflow
ansible-playbook -i inventory/hosts.yml playbooks/pnp_onboard_device.yml

# Individual tasks
ansible-playbook -i inventory/hosts.yml playbooks/pnp_claim_device.yml
ansible-playbook -i inventory/hosts.yml playbooks/pnp_check_status.yml
ansible-playbook -i inventory/hosts.yml playbooks/pnp_provision_device.yml

# Verbose mode
ansible-playbook -i inventory/hosts.yml playbooks/pnp_onboard_device.yml -vvv
```

### Shell Automation

```bash
# Complete automation
./scripts/automate_pnp.sh <SERIAL_NUMBER>

# Example
./scripts/automate_pnp.sh FCH1234ABCD
```

## Project Structure

```
ccc-pnp-c8000v/
├── README.md              # Complete documentation
├── QUICK_START.md         # This file
├── requirements.txt       # Python dependencies
├── .gitignore            # Git ignore rules
│
├── configs/              # Configuration files
│   └── config.example.yml
│
├── scripts/              # Python automation scripts
│   ├── catalyst_center_api.py
│   ├── pnp_claim_device.py
│   ├── pnp_monitor.py
│   ├── pnp_provision.py
│   └── automate_pnp.sh
│
├── ansible/              # Ansible automation
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── playbooks/
│       ├── pnp_onboard_device.yml
│       ├── pnp_claim_device.yml
│       ├── pnp_check_status.yml
│       └── pnp_provision_device.yml
│
└── docs/                 # Additional documentation
    ├── API_REFERENCE.md
    ├── TROUBLESHOOTING.md
    └── WORKFLOW.md
```

## Next Steps

After successful PNP onboarding:

1. **Verify Configuration**
   - SSH to device
   - Check running config
   - Test connectivity

2. **Day-N Configuration**
   - Apply additional templates
   - Configure routing protocols
   - Enable security features

3. **Monitoring**
   - Add to monitoring systems
   - Configure SNMP
   - Set up syslog

4. **Documentation**
   - Record deployment details
   - Update network diagrams
   - Document any customizations

## Support

- GitHub Issues: [Report issues](https://github.com/ters-golemi/ccc-pnp-c8000v/issues)
- Documentation: [Full README](README.md)
- Cisco DevNet: [Community support](https://developer.cisco.com/)

---

**Ready to automate? Run:** `./scripts/automate_pnp.sh <SERIAL_NUMBER>`
