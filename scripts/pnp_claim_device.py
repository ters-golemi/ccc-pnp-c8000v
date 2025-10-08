#!/usr/bin/env python3
"""
PNP Device Claim Script
Claims a device in Cisco Catalyst Center PNP
"""

import argparse
import yaml
import sys
import logging
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))

from catalyst_center_api import CatalystCenterAPI

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_config(config_file):
    """
    Load configuration from YAML file
    
    Args:
        config_file (str): Path to configuration file
        
    Returns:
        dict: Configuration data
    """
    try:
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f)
        logger.info(f"Configuration loaded from {config_file}")
        return config
    except Exception as e:
        logger.error(f"Failed to load configuration: {e}")
        sys.exit(1)


def claim_device(api, device_info, site_id):
    """
    Claim a device to a site
    
    Args:
        api (CatalystCenterAPI): API instance
        device_info (dict): Device information
        site_id (str): Site ID to claim device to
        
    Returns:
        dict: Claim response
    """
    # Prepare device claim payload
    device_claim_info = {
        "siteId": site_id,
        "deviceId": device_info.get('id'),
        "type": "Default",
        "imageInfo": {
            "imageId": "",
            "skip": True
        },
        "configInfo": {
            "configId": "",
            "configParameters": []
        }
    }
    
    logger.info(f"Claiming device {device_info.get('serialNumber')} to site {site_id}")
    
    try:
        response = api.claim_device(device_claim_info)
        return response
    except Exception as e:
        logger.error(f"Failed to claim device: {e}")
        raise


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Claim a device in Cisco Catalyst Center PNP'
    )
    parser.add_argument(
        '--config',
        required=True,
        help='Path to configuration file (YAML)'
    )
    parser.add_argument(
        '--serial',
        help='Device serial number (overrides config file)'
    )
    parser.add_argument(
        '--site',
        help='Site name or hierarchy (overrides config file)'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug logging'
    )
    
    args = parser.parse_args()
    
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Load configuration
    config = load_config(args.config)
    
    # Get Catalyst Center configuration
    cc_config = config.get('catalyst_center', {})
    host = cc_config.get('host')
    username = cc_config.get('username')
    password = cc_config.get('password')
    verify_ssl = cc_config.get('verify_ssl', False)
    version = cc_config.get('version', '3.1.0')
    
    if not all([host, username, password]):
        logger.error("Missing Catalyst Center credentials in configuration")
        sys.exit(1)
    
    # Get device configuration
    device_config = config.get('device', {})
    serial_number = args.serial or device_config.get('serial_number')
    site_name = args.site or device_config.get('site')
    
    if not serial_number:
        logger.error("Device serial number not provided")
        sys.exit(1)
    
    if not site_name:
        logger.error("Site name not provided")
        sys.exit(1)
    
    # Initialize API
    logger.info(f"Connecting to Catalyst Center at {host}")
    api = CatalystCenterAPI(host, username, password, verify_ssl, version)
    
    try:
        # Authenticate
        api.get_auth_token()
        
        # Get device by serial number
        logger.info(f"Looking up device with serial: {serial_number}")
        device = api.get_pnp_device_by_serial(serial_number)
        
        if not device:
            logger.error(f"Device not found: {serial_number}")
            logger.info("Make sure the device has contacted PNP service")
            sys.exit(1)
        
        device_id = device.get('id')
        device_state = device.get('deviceInfo', {}).get('state', 'Unknown')
        
        logger.info(f"Device found - ID: {device_id}, State: {device_state}")
        
        # Check if device is already claimed
        if device_state == 'Provisioned' or device_state == 'Planned':
            logger.warning(f"Device is already in '{device_state}' state")
            logger.info("Device may already be claimed or provisioned")
            response = input("Do you want to continue? (yes/no): ")
            if response.lower() != 'yes':
                logger.info("Operation cancelled by user")
                sys.exit(0)
        
        # Get site information
        logger.info(f"Looking up site: {site_name}")
        site = api.get_site_by_name(site_name)
        
        if not site:
            logger.error(f"Site not found: {site_name}")
            logger.info("Available sites:")
            sites = api.get_sites()
            for s in sites:
                print(f"  - {s.get('siteNameHierarchy', s.get('name'))}")
            sys.exit(1)
        
        site_id = site.get('id')
        logger.info(f"Site found - ID: {site_id}")
        
        # Claim device
        logger.info("Claiming device...")
        claim_response = claim_device(api, device, site_id)
        
        # Get task ID from response
        if isinstance(claim_response, dict):
            task_id = claim_response.get('response', {}).get('taskId')
            
            if task_id:
                logger.info(f"Claim initiated - Task ID: {task_id}")
                logger.info("Waiting for claim to complete...")
                
                # Wait for task completion
                final_status = api.wait_for_task_completion(task_id, timeout=300)
                
                if final_status.get('response', {}).get('isError'):
                    logger.error("Claim failed!")
                    logger.error(f"Error: {final_status.get('response', {}).get('failureReason', 'Unknown')}")
                    sys.exit(1)
                else:
                    logger.info("Device claimed successfully!")
                    logger.info("Device is now ready for provisioning")
            else:
                logger.warning("No task ID returned from claim operation")
                logger.info(f"Response: {claim_response}")
        else:
            logger.info(f"Claim response: {claim_response}")
        
        # Get updated device status
        logger.info("Retrieving updated device status...")
        updated_device = api.get_pnp_device_by_serial(serial_number)
        
        if updated_device:
            new_state = updated_device.get('deviceInfo', {}).get('state', 'Unknown')
            logger.info(f"Device state: {new_state}")
            
            print("\n" + "="*60)
            print("DEVICE CLAIM SUMMARY")
            print("="*60)
            print(f"Serial Number: {serial_number}")
            print(f"Device ID: {device_id}")
            print(f"Site: {site_name}")
            print(f"Current State: {new_state}")
            print("="*60)
        
        logger.info("Device claim completed successfully!")
        
    except Exception as e:
        logger.error(f"Error during device claim: {e}")
        if args.debug:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
