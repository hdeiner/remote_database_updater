#!/usr/bin/env bash

# First, add the GPG key for the official Docker repository to the system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository to APT sources
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Next, update the package database with the Docker packages from the newly added repo:
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq update

# Install Docker
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y docker-ce
sudo usermod -aG docker ubuntu
sudo systemctl restart docker
sudo systemctl enable docker

# Install figlet
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y figlet

# Install curl
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y curl

# Install awscli
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y awscli

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Vault (for cli access)
sudo DEBIAN_FRONTEND=noninteractive apt-get install unzip -y
curl -O https://releases.hashicorp.com/vault/1.5.0/vault_1.5.0_linux_amd64.zip
unzip vault_1.5.0_linux_amd64.zip
sudo mv vault /usr/local/bin/.
rm vault_1.5.0_linux_amd64.zip

# Install MySQL (for cli access)
sudo DEBIAN_FRONTEND=noninteractive apt-get install mysql-client -y
