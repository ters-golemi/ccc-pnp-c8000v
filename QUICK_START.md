# Quick Start Guide

Get started with PNP automation in 5 minutes!

## Prerequisites Check

Before you begin, ensure you have:

- [ ] Ubuntu workstation (20.04 LTS or later)
- [ ] Network connectivity to Catalyst Center
- [ ] Catalyst Center 3.1.X credentials
- [ ] Device serial number
- [ ] Site created in Catalyst Center

## Quick Setup (5 Minutes)

### 1. Install Tools (2 minutes)

```bash
# Update system
sudo apt update

# Install Python, Ansible, and Git
sudo apt install -y python3 python3-pip python3-venv ansible git

# Verify installations
python3 --version
ansible --version
```

### 2. Clone and Setup (2 minutes)

```bash
# Clone repository
git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git
cd ccc-pnp-c8000v

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure (1 minute)

```bash
# Copy example configuration
cp configs/config.example.yml configs/config.yml

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
