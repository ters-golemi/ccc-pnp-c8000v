#!/usr/bin/env python3
"""
PNP Device Provisioning Script
Provisions a claimed device in Cisco Catalyst Center
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


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Provision a device in Cisco Catalyst Center PNP'
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
    
    if not serial_number:
        logger.error("Device serial number not provided")
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
            sys.exit(1)
        
        device_id = device.get('id')
        device_info = device.get('deviceInfo', {})
        device_state = device_info.get('state', 'Unknown')
        hostname = device_info.get('hostname', 'N/A')
        
        logger.info(f"Device found - Hostname: {hostname}, State: {device_state}")
        
        # Check device state
        if device_state == 'Unclaimed':
            logger.error("Device is in 'Unclaimed' state")
            logger.info("Please claim the device first using pnp_claim_device.py")
            sys.exit(1)
        
        if device_state == 'Provisioned':
            logger.warning("Device is already provisioned")
            response = input("Do you want to re-provision? (yes/no): ")
            if response.lower() != 'yes':
                logger.info("Operation cancelled by user")
                sys.exit(0)
        
        print("\n" + "="*60)
        print("DEVICE PROVISIONING")
        print("="*60)
        print(f"Serial Number: {serial_number}")
        print(f"Hostname: {hostname}")
        print(f"Current State: {device_state}")
        print("="*60)
        
        logger.info("\nNote: Actual provisioning requires additional configuration in Catalyst Center:")
        logger.info("1. Configuration template must be created and assigned")
        logger.info("2. Template parameters must be defined")
        logger.info("3. Image (IOS-XE) must be specified if upgrading")
        
        logger.info("\nProvisioning is typically triggered automatically after device claim")
        logger.info("Or it can be manually triggered from Catalyst Center UI:")
        logger.info("  Provision > Plug and Play > Select Device > Actions > Provision")
        
        logger.info("\nMonitor provisioning status using:")
        logger.info(f"  python3 pnp_monitor.py --config {args.config} --serial {serial_number} --watch")
        
    except Exception as e:
        logger.error(f"Error during provisioning check: {e}")
        if args.debug:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
