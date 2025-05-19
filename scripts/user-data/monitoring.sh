#!/bin/bash

# Variables
EFS_ID="${efs_id}"
ACCESS_POINT_ID="${ap_id}"
MOUNT_DIR="${mount_dir}"
DOCKER_UID="${docker_uid}"
DOCKER_GID="${docker_gid}"
DOCKER_HOME=/var/lib/docker

# Install updates and EFS utils
sudo DEBIAN_FRONTEND=noninteractive apt update -y && \
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  wget gnupg2 apt-transport-https

# Install amazon-efs-utils from source
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
cd ..
rm -rf efs-utils

# Create docker group with specific GID
sudo groupadd -g $DOCKER_GID docker

# Create docker user with specific UID
sudo useradd -u $DOCKER_UID -g $DOCKER_GID docker

# Add EFS mount
sudo mkdir -p ${MOUNT_DIR}
sudo mount -t efs -o tls,accesspoint=${ACCESS_POINT_ID} ${EFS_ID}:/ ${MOUNT_DIR}

# Make it persistent
echo "${EFS_ID}:/ ${MOUNT_DIR} efs _netdev,tls,accesspoint=${ACCESS_POINT_ID} 0 0" | sudo tee -a /etc/fstab

# Install Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Clean up
sudo DEBIAN_FRONTEND=noninteractive apt clean -y
sudo rm -rf /var/lib/apt/lists/*