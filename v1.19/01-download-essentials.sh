#!/bin/bash
set -x
# keep track of the last executed command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

## Download essentials
mkdir -p 01_essentials
sudo apt update
sudo apt-get install --reinstall -y git vim build-essential openssh-server apt-transport-https curl --download-only
sudo mv /var/cache/apt/archives/*.deb 01_essentials/
sudo apt-get install --reinstall -y git vim build-essential openssh-server apt-transport-https curl
sudo rm /var/cache/apt/archives/*.deb


## Download docker 19.03
mkdir -p 02_docker
cat > 02_docker/docker.service << EOF
[Unit]
Description=Docker service
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/bin/dockerd

[Install]
WantedBy=multi-user.target
EOF


wget https://download.docker.com/linux/static/stable/x86_64/docker-19.03.9.tgz
mv docker-19.03.9.tgz 02_docker/
tar -xvf 02_docker/docker-19.03.9.tgz 
sudo cp docker/* /usr/bin/
sudo cp 02_docker/docker.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/docker.service
sudo systemctl enable docker
sudo systemctl restart docker
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

## Download Kubernetes 1.19
mkdir -p 03_kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-get install --reinstall -y kubelet=1.19.6-00 kubeadm=1.19.6-00 kubectl=1.19.6-00 --download-only
sudo mv /var/cache/apt/archives/*.deb 03_kubernetes/
sudo apt-get install --reinstall -y kubelet=1.19.6-00 kubeadm=1.19.6-00 kubectl=1.19.6-00
sudo rm /var/cache/apt/archives/*.deb

## Download nvidia-docker-2
mkdir -p 04_nvidiadocker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install --reinstall -y nvidia-docker2 --download-only
sudo mv /var/cache/apt/archives/*.deb 04_nvidiadocker/
sudo apt-get update && sudo apt-get install --reinstall -y nvidia-docker2
sudo rm /var/cache/apt/archives/*.deb

## Download docker images
mkdir -p 05_dockerimages
kubeadm config images pull
docker pull quay.io/coreos/flannel:v0.13.1-rc1
docker pull nvidia/k8s-device-plugin:v0.7.3
echo Saving images to file
docker save $(docker images | sed '1d' | awk '{print $1 ":" $2 }') -o 05_dockerimages/dockerimages.tar

## Download/Create config files
mkdir -p 06_config
wget https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.7.3/nvidia-device-plugin.yml
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
mv nvidia-device-plugin.yml 06_config
mv kube-flannel.yml 06_config



