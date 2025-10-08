#!/usr/bin/env python3
"""
Cisco Catalyst Center API Wrapper
Provides simplified interface for PNP operations
"""

import requests
import json
import time
import logging
from urllib3.exceptions import InsecureRequestWarning

# Disable SSL warnings for self-signed certificates
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class CatalystCenterAPI:
    """Wrapper class for Cisco Catalyst Center API operations"""
    
    def __init__(self, host, username, password, verify_ssl=False, version="3.1.0"):
        """
        Initialize Catalyst Center API connection
        
        Args:
            host (str): Catalyst Center hostname or IP
            username (str): Username for authentication
            password (str): Password for authentication
            verify_ssl (bool): Whether to verify SSL certificates
            version (str): API version
        """
        self.host = host
        self.username = username
        self.password = password
        self.verify_ssl = verify_ssl
        self.version = version
        self.base_url = f"https://{host}/dna/intent/api/v1"
        self.token = None
        self.headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
        
    def get_auth_token(self):
        """
        Authenticate and get API token
        
        Returns:
            str: Authentication token
        """
        auth_url = f"https://{self.host}/dna/system/api/v1/auth/token"
        
        try:
            response = requests.post(
                auth_url,
                auth=(self.username, self.password),
                headers={'Content-Type': 'application/json'},
                verify=self.verify_ssl
            )
            response.raise_for_status()
            
            self.token = response.json()['Token']
            self.headers['X-Auth-Token'] = self.token
            logger.info("Successfully authenticated to Catalyst Center")
            return self.token
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Authentication failed: {e}")
            raise
    
    def get_pnp_devices(self):
        """
        Get all PNP devices
        
        Returns:
            list: List of PNP devices
        """
        if not self.token:
            self.get_auth_token()
        
        url = f"{self.base_url}/onboarding/pnp-device"
        
        try:
            response = requests.get(
                url,
                headers=self.headers,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            devices = response.json()
            logger.info(f"Retrieved {len(devices)} PNP devices")
            return devices
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get PNP devices: {e}")
            raise
    
    def get_pnp_device_by_serial(self, serial_number):
        """
        Get PNP device by serial number
        
        Args:
            serial_number (str): Device serial number
            
        Returns:
            dict: Device information
        """
        if not self.token:
            self.get_auth_token()
        
        url = f"{self.base_url}/onboarding/pnp-device"
        params = {'serialNumber': serial_number}
        
        try:
            response = requests.get(
                url,
                headers=self.headers,
                params=params,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            devices = response.json()
            
            if devices and len(devices) > 0:
                logger.info(f"Found device with serial: {serial_number}")
                return devices[0]
            else:
                logger.warning(f"No device found with serial: {serial_number}")
                return None
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get device by serial: {e}")
            raise
    
    def claim_device(self, device_claim_info):
        """
        Claim a PNP device
        
        Args:
            device_claim_info (dict): Device claim information
            
        Returns:
            dict: Claim task response
        """
        if not self.token:
            self.get_auth_token()
        
        url = f"{self.base_url}/onboarding/pnp-device/claim"
        
        try:
            response = requests.post(
                url,
                headers=self.headers,
                json=device_claim_info,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            result = response.json()
            logger.info(f"Device claim initiated: {result}")
            return result
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to claim device: {e}")
            raise
    
    def get_device_claim_status(self, task_id):
        """
        Get status of a device claim task
        
        Args:
            task_id (str): Task ID from claim operation
            
        Returns:
            dict: Task status
        """
        if not self.token:
            self.get_auth_token()
        
        url = f"{self.base_url}/task/{task_id}"
        
        try:
            response = requests.get(
                url,
                headers=self.headers,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            task_status = response.json()
            logger.info(f"Task status: {task_status.get('response', {}).get('progress', 'Unknown')}")
            return task_status
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get task status: {e}")
            raise
    
    def get_sites(self):
        """
        Get all sites from Catalyst Center
        
        Returns:
            list: List of sites
        """
        if not self.token:
            self.get_auth_token()
        
        url = f"{self.base_url}/site"
        
        try:
            response = requests.get(
                url,
                headers=self.headers,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            sites = response.json().get('response', [])
            logger.info(f"Retrieved {len(sites)} sites")
            return sites
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get sites: {e}")
            raise
    
    def get_site_by_name(self, site_name):
        """
        Get site by name
        
        Args:
            site_name (str): Site name or hierarchy
            
        Returns:
            dict: Site information
        """
        sites = self.get_sites()
        
        for site in sites:
            if site.get('siteNameHierarchy') == site_name or site.get('name') == site_name:
                logger.info(f"Found site: {site_name}")
                return site
        
        logger.warning(f"Site not found: {site_name}")
        return None
    
    def get_templates(self):
        """
        Get all configuration templates
        
        Returns:
            list: List of templates
        """
        if not self.token:
            self.get_auth_token()
        
        url = f"{self.base_url}/template-programmer/project"
        
        try:
            response = requests.get(
                url,
                headers=self.headers,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            templates = response.json()
            logger.info(f"Retrieved templates")
            return templates
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get templates: {e}")
            raise
    
    def wait_for_task_completion(self, task_id, timeout=300, interval=10):
        """
        Wait for a task to complete
        
        Args:
            task_id (str): Task ID to monitor
            timeout (int): Maximum time to wait in seconds
            interval (int): Polling interval in seconds
            
        Returns:
            dict: Final task status
        """
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            task_status = self.get_device_claim_status(task_id)
            
            if task_status.get('response', {}).get('isError'):
                logger.error(f"Task failed: {task_status}")
                return task_status
            
            progress = task_status.get('response', {}).get('progress', '')
            if 'SUCCESS' in progress or 'completed' in progress.lower():
                logger.info(f"Task completed successfully")
                return task_status
            
            logger.info(f"Task in progress... waiting {interval} seconds")
            time.sleep(interval)
        
        logger.warning(f"Task timeout after {timeout} seconds")
        return task_status
    
    def delete_pnp_device(self, device_id):
        """
        Delete a PNP device (for cleanup)
        
        Args:
            device_id (str): Device ID to delete
            
        Returns:
            dict: Delete operation response
        """
        if not self.token:
            self.get_auth_token()
        
        url = f"{self.base_url}/onboarding/pnp-device/{device_id}"
        
        try:
            response = requests.delete(
                url,
                headers=self.headers,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            result = response.json()
            logger.info(f"Device deleted: {device_id}")
            return result
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to delete device: {e}")
            raise


if __name__ == "__main__":
    # Example usage
    print("Cisco Catalyst Center API Wrapper")
    print("This module provides API functions for PNP automation")
    print("Import this module in your scripts to use the CatalystCenterAPI class")
