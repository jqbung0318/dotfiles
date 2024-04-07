#!/bin/sh

# Run this in proxmox terminal
# works on i440fx
# please replace the ID (9000) to your suitable needs
# note that the reason of the ID is so big is to make sure this template sits below all your available VM/LXC

# getting cloud image
wget https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img

# create template sketch
qm create 9000 --name ubuntu2204-templ --memory 2048 --net0 virtio,bridge=vmbr0

# replace dockervm with your lvm
qm importdisk 9000 ubuntu-22.04-minimal-cloudimg-amd64.img dockervm -format qcow2
qm set 9000 --scsihw virtio-scsi-pci --scsi0 dockervm:vm-9000-disk-0

# replace dockervm with your lvm
# cloud init drive used to inject SSH public key
qm set 9000 --ide2 dockervm:cloudinit --boot c --bootdisk scsi0 --serial0 socket --vga serial0

# uncomment to resize
qm resize 9000 scsi0 +2G
qm set 9000 --ipconfig0 ip=dhcp

# cleanup
rm ubuntu-22.04-minimal-cloudimg-amd64.img 