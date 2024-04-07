#!/bin/sh

sudo apt-get update

# build-essential is required for nvidia drivers to compile
sudo apt-get install build-essential 

# TODO: change the version number
sudo apt install -y --no-install-recommends nvidia-cuda-toolkit nvidia-headless-545 nvidia-utils-545 libnvidia-encode-545
sudo apt-get install -y nvtop

# restart for driver effect
sudo reboot

# Nvidia container toolkit
# Nvidia docker has been deprecated as shown in https://github.com/NVIDIA/nvidia-docker
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# set the nvidia runtime template
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# SAMPLE: run docker container with gpu attached
# more in https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html
docker run --rm --gpus all nvidia/cuda nvidia-smi
docker run --rm --runtime=nvidia \
  -e NVIDIA_VISIBLE_DEVICES=all nvidia/cuda nvidia-smi