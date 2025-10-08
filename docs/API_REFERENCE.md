# Cisco Catalyst Center API Reference

This document provides reference information for the Cisco Catalyst Center (DNA Center) APIs used in this automation project.

## Table of Contents

- [Authentication](#authentication)
- [PNP Device APIs](#pnp-device-apis)
- [Site APIs](#site-apis)
- [Template APIs](#template-apis)
- [Task APIs](#task-apis)

## Authentication

### Get Authentication Token

Authenticate and receive an API token for subsequent requests.

**Endpoint:** `POST /dna/system/api/v1/auth/token`

**Authentication:** Basic Auth (username:password)

**Request:**
```bash
curl -k -X POST "https://<catalyst-center-ip>/dna/system/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'username:password' | base64)"
```

**Response:**
```json
{
  "Token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Token Usage:**
Use the token in the `X-Auth-Token` header for all subsequent API calls:
```
X-Auth-Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Token Expiration:**
Tokens typically expire after 1 hour. Re-authenticate when token expires.

## PNP Device APIs

### Get All PNP Devices

Retrieve list of all devices in PNP.

**Endpoint:** `GET /dna/intent/api/v1/onboarding/pnp-device`

**Headers:**
- `X-Auth-Token`: Authentication token
- `Content-Type`: application/json

**Request:**
```bash
curl -k -X GET "https://<catalyst-center-ip>/dna/intent/api/v1/onboarding/pnp-device" \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json"
```

**Response:**
```json
[
  {
    "id": "device-id-123",
    "deviceInfo": {
      "serialNumber": "FCH1234ABCD",
      "hostname": "v8000-2",
      "pid": "C8000V",
      "state": "Unclaimed",
      "source": "Network",
      "macAddress": "00:50:56:AA:BB:CC",
      "platformId": "C8000V",
      "softwareVersion": "17.6.1"
    }
  }
]
```

### Get PNP Device by Serial Number

Retrieve specific device by serial number.

**Endpoint:** `GET /dna/intent/api/v1/onboarding/pnp-device?serialNumber=<serial>`

**Parameters:**
- `serialNumber`: Device serial number

**Request:**
```bash
curl -k -X GET "https://<catalyst-center-ip>/dna/intent/api/v1/onboarding/pnp-device?serialNumber=FCH1234ABCD" \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json"
```

### Claim Device

Claim a device to a site.

**Endpoint:** `POST /dna/intent/api/v1/onboarding/pnp-device/claim`

**Request Body:**
```json
{
  "siteId": "site-uuid",
  "deviceId": "device-uuid",
  "type": "Default",
  "imageInfo": {
    "imageId": "",
    "skip": true
  },
  "configInfo": {
    "configId": "template-uuid",
    "configParameters": [
      {
        "key": "hostname",
        "value": "v8000-2"
      }
    ]
  }
}
```

**Request:**
```bash
curl -k -X POST "https://<catalyst-center-ip>/dna/intent/api/v1/onboarding/pnp-device/claim" \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json" \
  -d @claim_payload.json
```

**Response:**
```json
{
  "response": {
    "taskId": "task-uuid-123",
    "url": "/api/v1/task/task-uuid-123"
  }
}
```

### Delete PNP Device

Remove a device from PNP inventory.

**Endpoint:** `DELETE /dna/intent/api/v1/onboarding/pnp-device/<device-id>`

**Request:**
```bash
curl -k -X DELETE "https://<catalyst-center-ip>/dna/intent/api/v1/onboarding/pnp-device/<device-id>" \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json"
```

## Site APIs

### Get All Sites

Retrieve all sites from site hierarchy.

**Endpoint:** `GET /dna/intent/api/v1/site`

**Request:**
```bash
curl -k -X GET "https://<catalyst-center-ip>/dna/intent/api/v1/site" \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "response": [
    {
      "id": "site-uuid",
      "name": "Floor1",
      "siteNameHierarchy": "Global/US/San_Jose/Floor1",
      "parentId": "parent-site-uuid",
      "siteHierarchy": "uuid1/uuid2/uuid3/uuid4"
    }
  ]
}
```

### Get Site by Name

Query site by name or hierarchy.

**Endpoint:** `GET /dna/intent/api/v1/site?name=<site-name>`

**Parameters:**
- `name`: Site name or hierarchy

## Template APIs

### Get All Templates

Retrieve all configuration templates.

**Endpoint:** `GET /dna/intent/api/v1/template-programmer/project`

**Request:**
```bash
curl -k -X GET "https://<catalyst-center-ip>/dna/intent/api/v1/template-programmer/project" \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json"
```

### Get Template Details

Get detailed information about a specific template.

**Endpoint:** `GET /dna/intent/api/v1/template-programmer/template/<template-id>`

## Task APIs

### Get Task Status

Check status of a task (e.g., device claim).

**Endpoint:** `GET /dna/intent/api/v1/task/<task-id>`

**Request:**
```bash
curl -k -X GET "https://<catalyst-center-ip>/dna/intent/api/v1/task/<task-id>" \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "response": {
    "id": "task-uuid-123",
    "progress": "Device claimed successfully",
    "isError": false,
    "startTime": 1234567890,
    "endTime": 1234567900,
    "version": 1
  }
}
```

## Device State Transitions

PNP devices go through these states:

1. **Unclaimed**: Device has contacted PNP but not assigned to site
2. **Planned**: Device has been pre-provisioned but not yet discovered
3. **Onboarding**: Device claim is in progress
4. **Provisioned**: Device has been successfully provisioned
5. **Error**: An error occurred during provisioning

## Common HTTP Status Codes

- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `202 Accepted`: Request accepted for processing
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Authentication failed or token expired
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Rate Limiting

Catalyst Center API has rate limits:
- Default: 5 requests per second per user
- Burst: Up to 10 requests in short duration

Implement exponential backoff for retries.

## Python SDK

This project uses the `dnacentersdk` Python package:

```python
from dnacentersdk import DNACenterAPI

api = DNACenterAPI(
    username="admin",
    password="password",
    base_url="https://catalyst-center.example.com",
    verify=False
)

# Get PNP devices
devices = api.device_onboarding_pnp.get_device_list()

# Claim device
claim = api.device_onboarding_pnp.claim_a_device_to_a_site(
    site_id="site-uuid",
    device_id="device-uuid",
    type="Default"
)
```

## References

- [Cisco Catalyst Center API Documentation](https://developer.cisco.com/docs/dna-center/)
- [DNA Center SDK Python Documentation](https://dnacentersdk.readthedocs.io/)
- [Cisco DevNet](https://developer.cisco.com/)

## Support

For API issues:
1. Check Catalyst Center version compatibility
2. Verify API endpoint paths (may vary by version)
3. Review API logs in Catalyst Center
4. Consult Cisco DevNet forums
