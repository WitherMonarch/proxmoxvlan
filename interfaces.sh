#!/bin/bash

# List all available network interfaces
echo "Available network interfaces:"
ip -br link show | awk '{print $1}'

# Prompt user for inputs
read -p "Enter the physical interface name (e.g., eno1): " phy_iface
read -p "Enter the range of VLANs to allow (e.g., 2-4094): " vlan_range
read -p "Enter the VLAN ID for the connection interface (e.g., 100): " vlan_id
read -p "Enter the static IP address (e.g., 172.16.1.10): " static_ip
read -p "Enter the subnet in CIDR format (e.g., /24): " subnet_cidr
read -p "Enter the gateway (e.g., 172.16.1.1): " gateway

# Combine IP address with subnet in CIDR format (e.g., 172.16.1.10/24)
ip_with_subnet="$static_ip$subnet_cidr"

# Create the new network configuration file in the /tmp directory
cat <<EOF > /tmp/new_interfaces
auto lo
iface lo inet loopback

iface $phy_iface inet manual

auto vmbr0
iface vmbr0 inet manual
        bridge-ports $phy_iface
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-vids $vlan_range

auto vmbr0.$vlan_id
iface vmbr0.$vlan_id inet static
        address $ip_with_subnet
        gateway $gateway


source /etc/network/interfaces.d/*
EOF

echo "Network configuration has been saved to /tmp/new_interfaces!"

# Display the content of /tmp/new_interfaces to the user
echo "Here is the new network configuration:"
cat /tmp/new_interfaces

# Ask the user if the configuration is good
read -p "Does this configuration look good? (y/n): " confirmation

if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
    # Back up the current /etc/network/interfaces
    echo "Backing up /etc/network/interfaces to /etc/network/interfaces.bak..."
    cp /etc/network/interfaces /etc/network/interfaces.bak

    # Move /tmp/new_interfaces to /etc/network/interfaces
    echo "Moving /tmp/new_interfaces to /etc/network/interfaces..."
    mv /tmp/new_interfaces /etc/network/interfaces

    echo "Network configuration has been updated successfully!"
else
    echo "No changes have been made. Please review the configuration and try again."
fi

