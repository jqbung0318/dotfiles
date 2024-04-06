#!/bin/sh

# This script serves to add qemu guest agent to VM
# Typically use case in proxmox
# Note that you may first need to enable the QEMU Guest Agent in the Options tab of your VM in proxmox
# After enabling, install required files with this script and shutdown the VM
# Start again the VM in the proxmox

sudo apt update
sudo apt -y install qemu-guest-agent

systemctl enable qemu-guest-agent

# reboot does not take immediate effect
echo "Please shutdown your VM and enable guest agent in host"