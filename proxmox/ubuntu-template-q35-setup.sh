#!/bin/sh

# referring from https://github.com/UntouchedWagons/Ubuntu-CloudInit-Docs
# please replace the ID (9000) to your suitable needs
# note that the reason of the ID is so big is to make sure this template sits below all your available VM/LXC

wget -q https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

qm create 9000 --name "ubuntu-2204-cloudinit-template" --ostype l26 \
    --memory 1024 \
    --agent 1 \
    --bios ovmf --machine q35 --efidisk0 dockervm:0,pre-enrolled-keys=0 \
    --cpu host --socket 1 --cores 1 \
    --vga serial0 --serial0 socket  \
    --net0 virtio,bridge=vmbr0

qm importdisk 9000 jammy-server-cloudimg-amd64.img dockervm
qm set 9000 --scsihw virtio-scsi-pci --virtio0 dockervm:vm-9000-disk-1,discard=on
qm set 9000 --boot order=virtio0 # if HDD, omit this line
qm set 9000 --ide2 dockervm:cloudinit

# only run once, if you were to create multiple templates
mkdir -p /var/lib/vz/snippets
touch /var/lib/vz/snippets/vender.yaml
cat << EOF | tee /var/lib/vz/snippets/vendor.yaml
#cloud-config
runcmd:
    - apt update
    - apt install -y qemu-guest-agent git
    - systemctl start qemu-guest-agent
    - reboot
EOF

qm set 9000 --cicustom "vendor=local:snippets/vendor.yaml"
qm set 9000 --tags ubuntu-template,22.04,cloudinit
qm set 9000 --ciuser ubuntu
qm set 9000 --cipassword $(openssl passwd -6 "014289")
# qm set 9000 --sshkeys ~/.ssh/authorized_keys
qm set 9000 --ipconfig0 ip=dhcp
qm resize 9000 virtio0 +1.8G # base image has 2.2G, increase to 4.0G

# cleanup
rm jammy-server-cloudimg-amd64.img