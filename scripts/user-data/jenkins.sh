#!/bin/bash

# Variables
EFS_ID="${efs_id}"
ACCESS_POINT_ID="${ap_id}"
MOUNT_DIR="${mount_dir}"
JENKINS_UID="${jenkins_uid}"
JENKINS_GID="${jenkins_gid}"
JENKINS_HOME=/var/lib/jenkins

# Install amazon-efs-utils
sudo yum install -y amazon-efs-utils

# Create jenkins group with specific GID
sudo groupadd -g $${JENKINS_GID} jenkins

# Create jenkins user with specific UID
sudo useradd -u $${JENKINS_UID} -g $${JENKINS_GID} -m -d $${JENKINS_HOME} jenkins

# Add EFS mount
sudo mkdir -p $${MOUNT_DIR}
sudo mount -t efs -o tls,accesspoint=$${ACCESS_POINT_ID} $${EFS_ID}:/ $${MOUNT_DIR}

# Make it persistent
echo "$${EFS_ID}:/ $${MOUNT_DIR} efs _netdev,tls,accesspoint=$${ACCESS_POINT_ID} 0 0" | sudo tee -a /etc/fstab

# Install updates, Java (Jenkins dependency), EFS utils, and Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -Lo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo

sudo yum upgrade -y && sudo yum install -y fontconfig java-17-amazon-corretto jenkins

# Stop Jenkins in case it started
sudo systemctl stop jenkins

# Replace default Jenkins home with EFS mount
sudo rm -rf $${JENKINS_HOME}
sudo ln -s $${MOUNT_DIR} $${JENKINS_HOME}
sudo chown -R jenkins:jenkins $${JENKINS_HOME}

# Disable tmp.mount to avoid conflicts with EFS mount
sudo systemctl mask tmp.mount

# Enable and start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl daemon-reload
