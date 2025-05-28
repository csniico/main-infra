#!/bin/bash

# Variables
EFS_ID="${efs_id}"
ACCESS_POINT_ID="${ap_id}"
MOUNT_DIR="${mount_dir}"
DOCKER_UID="${docker_uid}"
DOCKER_GID="${docker_gid}"
DOCKER_HOME=/var/lib/docker

# Install amazon-efs-utils
sudo yum update -y
sudo yum install -y amazon-efs-utils

# Create docker group with specific GID
sudo groupadd -g $${DOCKER_GID} docker

# Create docker user with specific UID
sudo useradd -u $${DOCKER_UID} -g $${DOCKER_GID} -m -d $${DOCKER_HOME} docker

# Add EFS mount
sudo mkdir -p $${MOUNT_DIR}
sudo mount -t efs -o tls,accesspoint=$${ACCESS_POINT_ID} $${EFS_ID}:/ $${MOUNT_DIR}

# Make it persistent
echo "$${EFS_ID}:/ $${MOUNT_DIR} efs _netdev,tls,accesspoint=$${ACCESS_POINT_ID} 0 0" | sudo tee -a /etc/fstab

# Install Docker
sudo yum install -y docker

# Stop Docker in case it started
sudo systemctl stop docker

# Replace default Docker home with EFS mount
sudo rm -rf $${DOCKER_HOME}
sudo ln -s $${MOUNT_DIR} $${DOCKER_HOME}
sudo chown -R docker:docker $${DOCKER_HOME}

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl daemon-reload
