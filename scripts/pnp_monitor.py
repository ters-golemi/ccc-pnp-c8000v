#!/usr/bin/env python3
"""
PNP Device Monitor Script
Monitors PNP device status in Cisco Catalyst Center
"""

import argparse
import yaml
import sys
import logging
import time
from pathlib import Path
from tabulate import tabulate

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


def display_device_details(device):
    """
    Display detailed device information
    
    Args:
        device (dict): Device information
    """
    device_info = device.get('deviceInfo', {})
    
    print("\n" + "="*80)
    print("DEVICE DETAILS")
    print("="*80)
    
    details = [
        ["Serial Number", device_info.get('serialNumber', 'N/A')],
        ["Hostname", device_info.get('hostname', 'N/A')],
        ["Model", device_info.get('pid', 'N/A')],
        ["Device ID", device.get('id', 'N/A')],
        ["State", device_info.get('state', 'N/A')],
        ["Site", device_info.get('site', 'N/A')],
        ["Source", device_info.get('source', 'N/A')],
        ["MAC Address", device_info.get('macAddress', 'N/A')],
        ["Software Version", device_info.get('softwareVersion', 'N/A')],
        ["Platform", device_info.get('platformId', 'N/A')],
        ["Last Contact", device_info.get('lastContact', 'N/A')],
        ["Description", device_info.get('description', 'N/A')],
    ]
    
    print(tabulate(details, tablefmt='grid'))
    
    # Display workflow information if available
    workflow = device.get('workflowParameters', {})
    if workflow:
        print("\n" + "-"*80)
        print("WORKFLOW INFORMATION")
        print("-"*80)
        
        workflow_details = []
        for key, value in workflow.items():
            workflow_details.append([key, value])
        
        if workflow_details:
            print(tabulate(workflow_details, headers=['Parameter', 'Value'], tablefmt='grid'))
    
    # Display system information if available
    system_info = device.get('systemInfo', {})
    if system_info:
        print("\n" + "-"*80)
        print("SYSTEM INFORMATION")
        print("-"*80)
        
        system_details = []
        for key, value in system_info.items():
            if isinstance(value, (str, int, float, bool)):
                system_details.append([key, value])
        
        if system_details:
            print(tabulate(system_details, headers=['Parameter', 'Value'], tablefmt='grid'))
    
    print("="*80 + "\n")


def display_all_devices(devices):
    """
    Display summary of all PNP devices
    
    Args:
        devices (list): List of devices
    """
    if not devices:
        print("No PNP devices found")
        return
    
    print("\n" + "="*100)
    print(f"PNP DEVICES ({len(devices)} total)")
    print("="*100)
    
    table_data = []
    for device in devices:
        device_info = device.get('deviceInfo', {})
        table_data.append([
            device_info.get('serialNumber', 'N/A'),
            device_info.get('hostname', 'N/A'),
            device_info.get('pid', 'N/A'),
            device_info.get('state', 'N/A'),
            device_info.get('source', 'N/A'),
            (device.get('id', 'N/A')[:20] + '...' if len(device.get('id', 'N/A')) > 20 else device.get('id', 'N/A'))
        ])
    
    headers = ['Serial Number', 'Hostname', 'Model', 'State', 'Source', 'Device ID']
    print(tabulate(table_data, headers=headers, tablefmt='grid'))
    print("="*100 + "\n")


def monitor_device(api, serial_number, interval, duration):
    """
    Continuously monitor a device
    
    Args:
        api (CatalystCenterAPI): API instance
        serial_number (str): Device serial number
        interval (int): Polling interval in seconds
        duration (int): Total duration in seconds (0 for infinite)
    """
    start_time = time.time()
    iteration = 0
    
    logger.info(f"Starting continuous monitoring (interval: {interval}s)")
    
    try:
        while True:
            iteration += 1
            elapsed = int(time.time() - start_time)
            
            print(f"\n[Iteration {iteration}] Elapsed time: {elapsed}s")
            
            device = api.get_pnp_device_by_serial(serial_number)
            
            if device:
                device_info = device.get('deviceInfo', {})
                state = device_info.get('state', 'Unknown')
                hostname = device_info.get('hostname', 'N/A')
                
                print(f"Device: {serial_number}")
                print(f"Hostname: {hostname}")
                print(f"State: {state}")
                
                # Check if provisioning is complete
                if state == 'Provisioned':
                    logger.info("Device provisioning completed!")
                    break
            else:
                logger.warning(f"Device not found: {serial_number}")
            
            # Check duration
            if duration > 0 and elapsed >= duration:
                logger.info(f"Monitoring duration ({duration}s) reached")
                break
            
            # Wait for next iteration
            print(f"Waiting {interval} seconds...")
            time.sleep(interval)
            
    except KeyboardInterrupt:
        logger.info("\nMonitoring stopped by user")


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Monitor PNP device status in Cisco Catalyst Center'
    )
    parser.add_argument(
        '--config',
        required=True,
        help='Path to configuration file (YAML)'
    )
    parser.add_argument(
        '--serial',
        help='Device serial number to monitor'
    )
    parser.add_argument(
        '--list-all',
        action='store_true',
        help='List all PNP devices'
    )
    parser.add_argument(
        '--watch',
        action='store_true',
        help='Continuously monitor device status'
    )
    parser.add_argument(
        '--interval',
        type=int,
        default=30,
        help='Polling interval in seconds (default: 30)'
    )
    parser.add_argument(
        '--duration',
        type=int,
        default=0,
        help='Monitoring duration in seconds (default: 0 = infinite)'
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
    
    # Initialize API
    logger.info(f"Connecting to Catalyst Center at {host}")
    api = CatalystCenterAPI(host, username, password, verify_ssl, version)
    
    try:
        # Authenticate
        api.get_auth_token()
        
        # List all devices
        if args.list_all:
            logger.info("Retrieving all PNP devices...")
            devices = api.get_pnp_devices()
            display_all_devices(devices)
            return
        
        # Monitor specific device
        if not serial_number:
            logger.error("Device serial number not provided")
            logger.info("Use --serial option or add serial_number to config file")
            sys.exit(1)
        
        logger.info(f"Looking up device: {serial_number}")
        device = api.get_pnp_device_by_serial(serial_number)
        
        if not device:
            logger.error(f"Device not found: {serial_number}")
            logger.info("Use --list-all to see all available devices")
            sys.exit(1)
        
        # Display device details
        display_device_details(device)
        
        # Continuous monitoring if requested
        if args.watch:
            monitor_device(api, serial_number, args.interval, args.duration)
        
    except Exception as e:
        logger.error(f"Error during monitoring: {e}")
        if args.debug:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
