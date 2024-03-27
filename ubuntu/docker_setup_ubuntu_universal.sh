#!/bin/bash

# install required items
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y

# register and install docker
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# sudo apt-key fingerprint 0EBFCD88
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-cache policy docker-ce
sudo apt-get install -y docker-ce

# add current user to docker group
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl --no-pager status docker

# install docker compose
# sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
DOCKER_COMPOSE_LATEST_RELEASE=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest)
DOCKER_COMPOSE_LATEST_VERSION=$(basename "${DOCKER_COMPOSE_LATEST_RELEASE}")
echo "Latest Docker Compose version: ${DOCKER_COMPOSE_LATEST_VERSION}"

sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_LATEST_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# move setup files to Archive
mkdir -p Archive
mv docker_setup_ubuntu_universal.sh Archive
