# PNP Onboarding Workflow

This document provides detailed information about the Plug and Play (PNP) onboarding workflow for Cisco Catalyst 8000v routers.

## Table of Contents

- [Overview](#overview)
- [Workflow Phases](#workflow-phases)
- [Detailed Steps](#detailed-steps)
- [Network Topology](#network-topology)
- [Configuration Examples](#configuration-examples)
- [Sequence Diagrams](#sequence-diagrams)

## Overview

The PNP onboarding process automates the initial configuration of network devices, eliminating the need for manual console access. The workflow consists of several phases where the device discovers the Catalyst Center, registers itself, and receives its initial configuration.

## Workflow Phases

### Phase 1: Device Boot and Network Discovery

**What happens:**
1. Device powers on with factory default configuration
2. Device enables DHCP client on management interface
3. Device sends DHCP Discover message
4. DHCP server responds with IP address and Option 43

**Key Requirements:**
- Device must be in factory reset state
- DHCP server must be reachable
- DHCP Option 43 configured with Catalyst Center IP

**Duration:** 1-2 minutes

**Indicators of Success:**
- Device obtains IP address
- Device can ping DHCP server/gateway

**Common Issues:**
- DHCP not responding
- Option 43 not configured
- Network connectivity issues

### Phase 2: PNP Discovery

**What happens:**
1. Device extracts Catalyst Center IP from DHCP Option 43
2. Device initiates HTTPS connection to Catalyst Center
3. Device sends device information (serial number, model, etc.)
4. Catalyst Center registers device in PNP database

**Key Requirements:**
- Network connectivity to Catalyst Center
- Firewall permits HTTPS (port 443)
- PNP service enabled on Catalyst Center

**Duration:** 2-5 minutes

**Indicators of Success:**
- Device appears in Catalyst Center PNP list
- Device state shows "Unclaimed"

**Common Issues:**
- Cannot reach Catalyst Center
- Firewall blocking connection
- SSL certificate issues

### Phase 3: Device Claim (Automated)

**What happens:**
1. Automation script identifies device by serial number
2. Script retrieves site information
3. Script submits claim request to Catalyst Center API
4. Catalyst Center assigns device to site
5. Device state changes to "Planned" or "Onboarding"

**Key Requirements:**
- Device in "Unclaimed" state
- Target site exists in hierarchy
- API credentials valid

**Duration:** 1-2 minutes

**Indicators of Success:**
- Claim task completes successfully
- Device assigned to site
- Device state changes

**Common Issues:**
- Device already claimed
- Site doesn't exist
- API authentication failures

### Phase 4: Configuration Preparation

**What happens:**
1. Catalyst Center retrieves Day-0 template
2. Template variables populated with device-specific values
3. Configuration rendered and validated
4. Image upgrade prepared (if applicable)

**Key Requirements:**
- Day-0 template exists
- Template variables defined
- Template syntax valid

**Duration:** 1-2 minutes

**Indicators of Success:**
- Template renders successfully
- No template validation errors

**Common Issues:**
- Template not found
- Missing variables
- Template syntax errors

### Phase 5: Configuration Push

**What happens:**
1. Catalyst Center establishes connection to device
2. Configuration pushed to device
3. Device applies configuration
4. Device reloads if required
5. Device reconnects with new configuration

**Key Requirements:**
- Device credentials configured
- Device reachable during push
- Configuration syntax valid

**Duration:** 5-10 minutes

**Indicators of Success:**
- Configuration applied successfully
- Device reloads and reconnects
- Device state shows "Provisioned"

**Common Issues:**
- Configuration errors
- Device loses connectivity
- Credentials invalid

### Phase 6: Post-Provisioning

**What happens:**
1. Device appears in inventory with provisioned state
2. Device manageable through Catalyst Center
3. Device ready for Day-N configuration
4. Automation scripts verify completion

**Key Requirements:**
- Device responsive
- Configuration persisted

**Duration:** Immediate

**Indicators of Success:**
- Device state "Provisioned"
- Device in inventory
- Device configuration as expected

## Detailed Steps

### Step 1: Prepare Infrastructure

**Before starting automation:**

1. **Configure DHCP Server**

   On Cisco IOS router:
   ```
   ip dhcp excluded-address 192.168.1.1 192.168.1.10
   !
   ip dhcp pool PNP_POOL
    network 192.168.1.0 255.255.255.0
    default-router 192.168.1.1
    dns-server 8.8.8.8
    option 43 ascii "5A1N;B2;K4;I172.16.1.10;J80"
   ```

   **Option 43 Format Explanation:**
   - `5A1N` - Fixed header
   - `B2` - Bootstrap method (2 = HTTPS)
   - `K4` - Retry count
   - `I172.16.1.10` - Catalyst Center IP address
   - `J80` - Port (80 for HTTP, 443 for HTTPS)

2. **Configure Site Hierarchy**

   In Catalyst Center:
   - Navigate to **Design > Network Hierarchy**
   - Create site structure:
     ```
     Global
     └── US
         └── San_Jose
             └── Floor1
     ```

3. **Create Day-0 Template**

   Navigate to **Tools > Template Editor**
   
   Example template:
   ```
   !
   hostname $hostname
   !
   ! WAN Interface Configuration
   interface $wan_interface
    description WAN Connection
    ip address $wan_ip $wan_mask
    no shutdown
   !
   ! LAN Interface Configuration
   interface $lan_interface
    description LAN Connection
    ip address $lan_ip $lan_mask
    no shutdown
   !
   ! Default Route
   ip route 0.0.0.0 0.0.0.0 $gateway
   !
   ! DNS Configuration
   ip name-server $dns_server1 $dns_server2
   !
   ! NTP Configuration
   ntp server $ntp_server
   !
   ! Enable Services
   ip domain-name $domain_name
   crypto key generate rsa modulus 2048
   !
   ip ssh version 2
   !
   ! Management Access
   line vty 0 4
    transport input ssh
    login local
   !
   username $admin_username privilege 15 secret $admin_password
   !
   enable secret $enable_password
   !
   ```

4. **Configure Device Credentials**

   Navigate to **Design > Network Settings > Device Credentials**
   - Add CLI credentials
   - Add SNMP credentials

### Step 2: Prepare Automation Environment

1. **Install Prerequisites**

   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip ansible git
   ```

2. **Navigate to Project Directory**

   ```bash
   # Access project directory (assumes project files are available locally)
   cd ccc-pnp-c8000v
   ```

3. **Create Virtual Environment**

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

4. **Install Dependencies**

   ```bash
   pip install -r requirements.txt
   ```

5. **Configure Settings**

   ```bash
   cp configs/config.example.yml configs/config.yml
   vim configs/config.yml
   ```

### Step 3: Prepare Device

1. **Factory Reset Device**

   On device console:
   ```
   enable
   write erase
   reload
   ```

   When prompted: "Proceed with reload? [confirm]" - Press Enter
   When prompted: "Save configuration?" - Enter **no**

2. **Connect Device to Network**

   - Connect WAN interface to PNP network
   - Ensure physical link is up
   - Device should get DHCP address

3. **Verify Device Boot**

   On console, watch for:
   ```
   %PNPA-5-PNPA_DISCOVERY: PnP Discovery started
   %PNPA-5-PNPA_HTTP_CONNECTING: HTTP connection to PnP server 172.16.1.10
   ```

### Step 4: Run Automation

**Method 1: Complete Automation**

```bash
./scripts/automate_pnp.sh FCH1234ABCD
```

**Method 2: Step-by-Step Python Scripts**

```bash
# Check device status
python3 scripts/pnp_monitor.py --config configs/config.yml --serial FCH1234ABCD

# Claim device
python3 scripts/pnp_claim_device.py --config configs/config.yml

# Monitor provisioning
python3 scripts/pnp_monitor.py --config configs/config.yml --serial FCH1234ABCD --watch
```

**Method 3: Ansible Playbooks**

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/pnp_onboard_device.yml
```

### Step 5: Monitor Progress

**Using Scripts:**

```bash
# Continuous monitoring
python3 scripts/pnp_monitor.py \
  --config configs/config.yml \
  --serial FCH1234ABCD \
  --watch \
  --interval 30
```

**Using Catalyst Center UI:**

1. Navigate to **Provision > Plug and Play**
2. Locate device by serial number
3. Monitor state changes
4. View provisioning logs

**Expected State Transitions:**

```
Unclaimed → Planned → Onboarding → Provisioned
```

### Step 6: Verify Completion

1. **Check Device State**

   ```bash
   python3 scripts/pnp_monitor.py --config configs/config.yml --serial FCH1234ABCD
   ```

   Expected: State = "Provisioned"

2. **Verify in Catalyst Center**

   Navigate to **Provision > Inventory**
   - Device should appear in inventory
   - Reachability status: Reachable
   - Collection status: Managed

3. **Test Device Access**

   ```bash
   ssh admin@<device-ip>
   ```

4. **Verify Configuration**

   On device:
   ```
   show running-config
   show ip interface brief
   show version
   ```

## Network Topology

```
                    Internet
                        |
                        |
                [Firewall/Router]
                        |
                        |
        +--------------+----------------+
        |              |                |
        |              |                |
   [Catalyst      [C1Kv]          [v8000-1]
    Center]           |                |
                      |                |
                  [Switch]             |
                      |                |
                  [v8000-2]____________|
                (PNP Device)
```

### Network Requirements

**Connectivity:**
- v8000-2 → C1Kv: Layer 2/3 connectivity
- C1Kv → Catalyst Center: HTTPS (port 443)
- v8000-2 must reach Catalyst Center during PNP

**IP Addressing:**
- PNP Network: 192.168.1.0/24 (example)
- Catalyst Center: 172.16.1.10 (example)
- v8000-2 (PNP): DHCP assigned
- v8000-2 (Post-PNP): As per Day-0 config

**DHCP:**
- DHCP server on C1Kv or dedicated server
- Option 43 configured
- IP pool for PNP devices

## Configuration Examples

### Complete Day-0 Configuration

```
!
hostname v8000-2
!
interface GigabitEthernet1
 description WAN-Connection-to-Internet
 ip address 192.168.1.10 255.255.255.0
 negotiation auto
 no shutdown
!
interface GigabitEthernet2
 description LAN-Connection-to-Internal
 ip address 10.0.0.1 255.255.255.0
 negotiation auto
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.1.1
!
ip name-server 8.8.8.8
ip name-server 8.8.4.4
!
ntp server time.nist.gov
!
ip domain-name example.com
!
username admin privilege 15 secret C1sco12345
enable secret C1sco12345
!
ip ssh version 2
ip scp server enable
!
line vty 0 4
 transport input ssh
 login local
!
end
```

## Sequence Diagrams

### Complete PNP Workflow

```
Device          DHCP Server     Catalyst Center     Automation Script
  |                  |                  |                    |
  |-- DHCP Discover->|                  |                    |
  |<-- DHCP Offer ---|                  |                    |
  |    (with Opt 43) |                  |                    |
  |                  |                  |                    |
  |-- PNP Hello -------------------->|                    |
  |<-- PNP Response -------------------|                    |
  |                  |                  |                    |
  |                  |                  |<-- Get Devices ---|
  |                  |                  |--- Device List -->|
  |                  |                  |                    |
  |                  |                  |<-- Claim Device --|
  |                  |                  |--- Task ID ------>|
  |                  |                  |                    |
  |<-- Day-0 Config -------------------|                    |
  |-- Apply Config ->|                  |                    |
  |-- Reload ------->|                  |                    |
  |                  |                  |                    |
  |-- Re-register ------------------>|                    |
  |<-- Confirmation -------------------|                    |
  |                  |                  |                    |
  |                  |                  |<-- Get Status ----|
  |                  |                  |--- Provisioned -->|
```

## Timeline Estimates

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Device Boot | 1-2 min | 1-2 min |
| DHCP Assignment | 30 sec | 2-3 min |
| PNP Discovery | 2-5 min | 4-8 min |
| Device Claim | 1-2 min | 5-10 min |
| Config Preparation | 1-2 min | 6-12 min |
| Config Push | 5-10 min | 11-22 min |
| Device Reload | 2-3 min | 13-25 min |
| Re-registration | 1-2 min | 14-27 min |
| **Total** | **14-27 min** | - |

## Best Practices

1. **Pre-Staging:**
   - Test DHCP before device deployment
   - Validate templates in lab
   - Create site hierarchy in advance

2. **Monitoring:**
   - Use continuous monitoring during onboarding
   - Watch device console for errors
   - Monitor Catalyst Center logs

3. **Error Handling:**
   - Have rollback plan ready
   - Document any customizations
   - Keep factory reset procedure handy

4. **Documentation:**
   - Record serial numbers
   - Document site assignments
   - Track configuration versions

5. **Security:**
   - Use strong credentials
   - Enable SSH only
   - Implement proper access control

## Next Steps After PNP

Once device is provisioned:

1. **Verification:**
   - Test connectivity
   - Verify configuration
   - Check services

2. **Day-N Configuration:**
   - Apply additional templates
   - Configure routing protocols
   - Enable security features

3. **Monitoring:**
   - Add to monitoring systems
   - Configure SNMP
   - Set up syslog

4. **Compliance:**
   - Run compliance checks
   - Apply policy
   - Document deployment

## References

- [Cisco PNP Documentation](https://www.cisco.com/c/en/us/td/docs/cloud-systems-management/network-automation-and-management/dna-center/2-3-3/user_guide/b_cisco_dna_center_ug_2_3_3/b_cisco_dna_center_ug_2_3_3_chapter_0110.html)
- [Catalyst 8000v Configuration Guide](https://www.cisco.com/c/en/us/td/docs/routers/C8000V/Configuration/c8000v-installation-configuration-guide.html)
- [Catalyst Center API Guide](https://developer.cisco.com/docs/dna-center/)
