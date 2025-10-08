# Troubleshooting Guide

This guide helps you troubleshoot common issues with Cisco Catalyst Center PNP automation.

## Table of Contents

- [Device Discovery Issues](#device-discovery-issues)
- [Authentication Issues](#authentication-issues)
- [Device Claim Issues](#device-claim-issues)
- [Provisioning Issues](#provisioning-issues)
- [Network Connectivity Issues](#network-connectivity-issues)
- [Template Issues](#template-issues)
- [Script Execution Issues](#script-execution-issues)

## Device Discovery Issues

### Issue: Device not appearing in PNP list

**Symptoms:**
- Device powers on but doesn't appear in Catalyst Center PNP
- Script cannot find device by serial number

**Possible Causes:**
1. DHCP not configured or not reaching device
2. DHCP Option 43 not configured correctly
3. Network connectivity issues
4. Device not in factory reset state
5. PNP service not enabled on Catalyst Center

**Solutions:**

#### 1. Verify DHCP Configuration

Check if device is getting IP address:
```bash
# On device console
show ip interface brief
```

Expected output should show IP on management interface.

#### 2. Verify DHCP Option 43

DHCP server must provide Option 43 with Catalyst Center IP:

**Cisco IOS DHCP:**
```
ip dhcp pool PNP_POOL
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 option 43 ascii "5A1N;B2;K4;I172.16.1.10;J80"
```

Format: `5A1N;B2;K4;I<DNAC-IP>;J80`

**Linux ISC DHCP:**
```
subnet 192.168.1.0 netmask 255.255.255.0 {
  option routers 192.168.1.1;
  option vendor-specific-information "5A1N;B2;K4;I172.16.1.10;J80";
}
```

#### 3. Verify DNS (Alternative to Option 43)

Device can also discover Catalyst Center via DNS:

Create DNS A record:
```
pnpserver.localdomain  A  172.16.1.10
```

#### 4. Check Network Connectivity

Verify device can reach Catalyst Center:
```bash
# On device console
ping 172.16.1.10
```

#### 5. Verify PNP Service

In Catalyst Center:
- Navigate to **System > Settings > PNP Connect**
- Ensure PNP service is **Enabled**
- Check virtual account is configured

#### 6. Factory Reset Device

Device must be in factory default state:
```bash
# On device console
write erase
reload
```

When prompted to save configuration: **No**

#### 7. Check PNP Logs

View logs in Catalyst Center:
- **System > Logs**
- Filter by: `pnp`
- Look for device connection attempts

### Issue: Device shows as "Unknown" in PNP

**Solution:**
- Device serial number may not be in Cisco database
- Manually add device using CSV import
- Contact Cisco TAC if genuine device

## Authentication Issues

### Issue: 401 Unauthorized Error

**Symptoms:**
```
Authentication failed: 401 Client Error: Unauthorized
```

**Solutions:**

#### 1. Verify Credentials

Check username/password in `configs/config.yml`:
```yaml
catalyst_center:
  username: "admin"
  password: "correct_password"
```

#### 2. Check User Permissions

User must have appropriate role:
- Network Admin (minimum)
- Super Admin (recommended for automation)

Verify in Catalyst Center:
- **System > Users**
- Check user role assignments

#### 3. Check Account Status

Account might be locked due to failed login attempts:
- **System > Users**
- Unlock account if needed

#### 4. Password Special Characters

If password contains special characters, ensure proper escaping:
```yaml
# Use quotes for special characters
password: "P@ssw0rd!"
```

### Issue: Token Expired

**Symptoms:**
```
Token expired or invalid
```

**Solution:**
Tokens expire after 1 hour. Script automatically re-authenticates.
If issue persists, check system time synchronization:
```bash
# Check time
date

# Sync time if needed
sudo ntpdate -u time.nist.gov
```

## Device Claim Issues

### Issue: Device claim fails

**Symptoms:**
```
Failed to claim device: 400 Bad Request
Device claim failed
```

**Solutions:**

#### 1. Verify Device State

Device must be in "Unclaimed" state:
```bash
python3 scripts/pnp_monitor.py --config configs/config.yml --serial FCH1234ABCD
```

If state is "Provisioned" or "Planned", device is already claimed.

#### 2. Verify Site Exists

Site must exist in hierarchy:
```bash
python3 scripts/pnp_monitor.py --config configs/config.yml --list-all
```

Check available sites in Catalyst Center:
- **Design > Network Hierarchy**

#### 3. Check Serial Number

Verify serial number is correct:
```bash
# On device
show version | include Serial
```

#### 4. Reset Device in PNP

If device is in error state:
- Navigate to **Provision > Plug and Play**
- Select device
- Click **Delete**
- Reload device to re-register

#### 5. Check Template Assignment

If using templates, ensure:
- Template exists in Catalyst Center
- Template is valid (no syntax errors)
- Template is assigned to device type

## Provisioning Issues

### Issue: Provisioning stuck or fails

**Symptoms:**
- Device stays in "Onboarding" state
- Provisioning never completes
- Device shows error in PNP

**Solutions:**

#### 1. Check Template Syntax

Verify Day-0 template has no errors:
- **Tools > Template Editor**
- Select template
- Click **Validate**

Common template errors:
```
# Missing variable definition
hostname $hostname  # Must define $hostname

# Typo in variable name
ip address $wan_ipaddress $wan_mask  # Inconsistent naming
```

#### 2. Verify Template Variables

All template variables must have values:
```yaml
template:
  parameters:
    hostname: "v8000-2"
    wan_ip: "192.168.1.10"
    # All variables used in template
```

#### 3. Check Device Credentials

Device needs CLI credentials for configuration push:
- **Design > Network Settings > Device Credentials**
- Verify CLI credentials are configured

#### 4. Check Device Connectivity

During provisioning, device must maintain connectivity:
```bash
# Ping device from Catalyst Center
# Or check device console for connectivity
```

#### 5. Review Device Logs

On device console:
```bash
show logging | include PNP
show logging | include %SYS
```

#### 6. Check Image Compatibility

If upgrading image, ensure:
- Image is uploaded to Catalyst Center
- Image is compatible with device model
- Sufficient storage on device

Skip image upgrade for testing:
```yaml
options:
  skip_image_upgrade: true
```

## Network Connectivity Issues

### Issue: Cannot reach Catalyst Center

**Symptoms:**
```
Failed to connect to Catalyst Center
Connection timeout
```

**Solutions:**

#### 1. Verify Network Connectivity

```bash
# Ping Catalyst Center
ping catalyst-center.example.com

# Check DNS resolution
nslookup catalyst-center.example.com

# Check port connectivity
telnet catalyst-center.example.com 443
```

#### 2. Check Firewall Rules

Ensure firewall allows:
- Port 443 (HTTPS) to Catalyst Center
- Port 80 (HTTP) if redirecting to HTTPS

#### 3. Verify SSL Certificate

For self-signed certificates:
```yaml
catalyst_center:
  verify_ssl: false
```

For production, install proper certificate:
```bash
# Download certificate
echo | openssl s_client -showcerts -connect catalyst-center.example.com:443 2>/dev/null | openssl x509 -outform PEM > dnac.pem

# Install certificate
sudo cp dnac.pem /usr/local/share/ca-certificates/dnac.crt
sudo update-ca-certificates
```

#### 4. Check Proxy Settings

If using proxy, configure:
```bash
export https_proxy=http://proxy.example.com:8080
export http_proxy=http://proxy.example.com:8080
```

## Template Issues

### Issue: Template not found

**Symptoms:**
```
Template not found: C8000V-Day0-Template
```

**Solutions:**

#### 1. Create Template

Navigate to **Tools > Template Editor**:
1. Click **Add Template**
2. Select project
3. Create template with proper syntax

#### 2. Verify Template Name

Check exact name in Catalyst Center matches config:
```yaml
template:
  name: "C8000V-Day0-Template"  # Must match exactly
```

#### 3. Sample Day-0 Template

Basic C8000v template:
```
hostname $hostname
!
interface GigabitEthernet1
 description WAN
 ip address $wan_ip $wan_mask
 no shutdown
!
interface GigabitEthernet2
 description LAN
 ip address $lan_ip $lan_mask
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 $gateway
!
```

## Script Execution Issues

### Issue: Python module not found

**Symptoms:**
```
ModuleNotFoundError: No module named 'requests'
```

**Solution:**
```bash
# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Issue: Permission denied

**Symptoms:**
```
bash: ./scripts/automate_pnp.sh: Permission denied
```

**Solution:**
```bash
# Make script executable
chmod +x scripts/automate_pnp.sh

# Or run with bash
bash scripts/automate_pnp.sh FCH1234ABCD
```

### Issue: Config file not found

**Symptoms:**
```
Configuration file not found: configs/config.yml
```

**Solution:**
```bash
# Copy example config
cp configs/config.example.yml configs/config.yml

# Edit with your details
vim configs/config.yml
```

### Issue: YAML parsing error

**Symptoms:**
```
yaml.parser.ParserError: while parsing a block mapping
```

**Solution:**
Check YAML syntax:
- Proper indentation (2 spaces)
- No tabs
- Quotes around values with special characters

```yaml
# Correct
username: "admin"
password: "P@ssw0rd!"

# Incorrect - no quotes
password: P@ssw0rd!
```

## Advanced Troubleshooting

### Enable Debug Logging

Add `--debug` flag to scripts:
```bash
python3 scripts/pnp_claim_device.py --config configs/config.yml --debug
```

### Ansible Verbose Mode

```bash
ansible-playbook -i inventory/hosts.yml playbooks/pnp_onboard_device.yml -vvv
```

### API Request Debugging

Test API directly with curl:
```bash
# Get token
TOKEN=$(curl -k -s -X POST "https://catalyst-center.example.com/dna/system/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'admin:password' | base64)" | jq -r '.Token')

# Test API call
curl -k -X GET "https://catalyst-center.example.com/dna/intent/api/v1/onboarding/pnp-device" \
  -H "X-Auth-Token: $TOKEN" \
  -H "Content-Type: application/json" | jq
```

### Check Python Version

```bash
python3 --version
# Should be 3.8 or higher
```

### Verify Network Path

```bash
# Traceroute to Catalyst Center
traceroute catalyst-center.example.com

# Check routing
ip route get <catalyst-center-ip>
```

## Getting Help

If issues persist:

1. **Check Logs:**
   - Catalyst Center: System > Logs
   - Device: `show logging`
   - Script: Enable debug mode

2. **Review Documentation:**
   - README.md
   - API_REFERENCE.md
   - WORKFLOW.md

3. **Community Support:**
   - Cisco DevNet Community
   - GitHub Issues
   - Stack Overflow (tag: cisco-dna-center)

4. **Cisco TAC:**
   - For Catalyst Center issues
   - For device issues
   - For licensing issues

## Common Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| 401 Unauthorized | Invalid credentials | Check username/password |
| 403 Forbidden | Insufficient permissions | Check user role |
| 404 Not Found | Resource doesn't exist | Verify serial number, site name |
| 500 Internal Server Error | Catalyst Center error | Check Catalyst Center logs |
| Connection timeout | Network issue | Check connectivity, firewall |
| Token expired | Token older than 1 hour | Script re-authenticates automatically |
| Device not found | Serial number invalid | Verify serial number |
| Site not found | Site doesn't exist | Check site hierarchy |
| Template not found | Template missing | Create template in Catalyst Center |

## Prevention

Best practices to avoid issues:

1. **Pre-flight Checks:**
   - Verify network connectivity
   - Test credentials before automation
   - Confirm device in factory reset state

2. **Configuration Management:**
   - Use version control for configs
   - Keep backup of working configs
   - Document changes

3. **Monitoring:**
   - Monitor PNP status regularly
   - Set up alerts in Catalyst Center
   - Review logs proactively

4. **Testing:**
   - Test in lab environment first
   - Verify templates before production use
   - Test with one device before bulk operations
