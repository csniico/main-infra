#!/bin/bash

# Variables
EFS_ID="${efs_id}"
ACCESS_POINT_ID="${ap_id}"
MOUNT_DIR="${mount_dir}"
JENKINS_UID="${jenkins_uid}"
JENKINS_GID="${jenkins_gid}"
JENKINS_HOME=/var/lib/jenkins

# Install updates, Java (Jenkins dependency), and EFS utils
sudo DEBIAN_FRONTEND=noninteractive apt update -y && \
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  fontconfig openjdk-17-jre wget gnupg2 apt-transport-https

# Install amazon-efs-utils from source
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
cd ..
rm -rf efs-utils

# Create jenkins group with specific GID
sudo groupadd -g $${JENKINS_GID} jenkins

# Create jenkins user with specific UID
sudo useradd -u $${JENKINS_UID} -g $${JENKINS_GID} -m -d $${JENKINS_HOME} jenkins

# Add EFS mount
sudo mkdir -p $${MOUNT_DIR}
sudo mount -t efs -o tls,accesspoint=$${ACCESS_POINT_ID} $${EFS_ID}:/ $${MOUNT_DIR}

# Make it persistent
echo "$${EFS_ID}:/ $${MOUNT_DIR} efs _netdev,tls,accesspoint=$${ACCESS_POINT_ID} 0 0" | sudo tee -a /etc/fstab

# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list

sudo DEBIAN_FRONTEND=noninteractive apt update -y && \
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  jenkins

# Stop Jenkins in case it started
sudo systemctl stop jenkins

# Replace default Jenkins home with EFS mount
sudo rm -rf $${JENKINS_HOME}
sudo ln -s $${MOUNT_DIR} $${JENKINS_HOME}
sudo chown -R jenkins:jenkins $${JENKINS_HOME}

# Enable and start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Clean up
sudo DEBIAN_FRONTEND=noninteractive apt clean -y
sudo rm -rf /var/lib/apt/lists/*
