#!/bin/bash
set -x
# keep track of the last executed command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

## Uninstall existing docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd


## Download essentials
mkdir -p 01_essentials

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg --download-only
sudo mv /var/cache/apt/archives/*.deb 01_essentials/
sudo apt-get install -y ca-certificates curl gnupg

# sudo install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# sudo chmod a+r /etc/apt/keyrings/docker.gpg

# echo \
#   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#   "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt-get install --reinstall -y liberror-perl git-man git vim net-tools build-essential openssh-server apt-transport-https curl ca-certificates curl gnupg --download-only
sudo mv /var/cache/apt/archives/*.deb 01_essentials/
sudo apt-get install --reinstall -y liberror-perl git-man git vim net-tools build-essential openssh-server apt-transport-https curl ca-certificates curl gnupg
sudo rm /var/cache/apt/archives/*.deb


wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
sudo cp containerd.service /etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

wget https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.3.0.tgz

wget https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz
tar -xvf nerdctl-1.5.0-linux-amd64.tar.gz
sudo cp nerdctl /usr/local/bin/


# sudo groupadd docker
# sudo usermod -aG docker $USER
# newgrp docker
# docker run hello-world


## Download Kubernetes 1.19
mkdir -p 03_kubernetes
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install --reinstall -y kubelet=1.25.12-00 kubeadm=1.25.12-00 kubectl=1.25.12-00 --download-only
sudo mv /var/cache/apt/archives/*.deb 03_kubernetes/
sudo apt-get install --reinstall -y kubelet=1.25.12-00 kubeadm=1.25.12-00 kubectl=1.25.12-00
sudo rm /var/cache/apt/archives/*.deb

## Fix containerd
sudo apt purge containerd.io -y
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
sudo tar Czxvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
sudo mv containerd.service /usr/lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl restart containerd




sudo mkdir -p /etc/containerd/
containerd config default | sudo tee /etc/containerd/config.toml

## Download docker images
mkdir -p 05_dockerimages
kubeadm config images pull

docker pull k8s.gcr.io/kube-proxy:v1.25.12
docker pull quay.io/coreos/flannel:v0.13.1-rc1
docker pull nvidia/k8s-device-plugin:v0.7.3
echo Saving images to file
sudo docker save $(sudo docker images | sed '1d' | awk '{print $1 ":" $2 }') -o 05_dockerimages/dockerimages.tar
## Download/Create config files
mkdir -p 06_config
wget https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.7.3/nvidia-device-plugin.yml
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
mv nvidia-device-plugin.yml 06_config
mv kube-flannel.yml 06_config
