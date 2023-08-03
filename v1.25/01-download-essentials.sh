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

containerd config default > config.toml
sudo cp config.toml /etc/containerd/
sudo systemctl restart containerd
 
wget https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz
tar -xvf nerdctl-1.5.0-linux-amd64.tar.gz
sudo cp nerdctl /usr/local/bin/

git clone https://github.com/NVIDIA/gpu-operator
tar -xvf gpu-operator-v23.3.2.tgz


###### Download following container images
# nvcr.io/nvidia/cloud-native/gpu-operator-validator:latest
# nvcr.io/nvidia/cloud-native/k8s-driver-manager:v0.6.2 
# nvcr.io/nvidia/cloud-native/k8s-mig-manager:v0.5.3-ubuntu20.04
# nvcr.io/nvidia/cloud-native/vgpu-device-manager:v0.2.3
# nvcr.io/nvidia/cuda:12.2.0-base-ubi8 
# nvcr.io/nvidia/driver:latest 
# nvcr.io/nvidia/driver:535.86.10 
# nvcr.io/nvidia/gpu-feature-discovery:v0.8.1-ubi8 
# nvcr.io/nvidia/gpu-operator:latest 
# nvcr.io/nvidia/k8s-device-plugin:v0.14.1-ubi8 
# nvcr.io/nvidia/k8s/container-toolkit:v1.13.4-ubuntu20.04 
# nvcr.io/nvidia/k8s/container-toolkit:latest 
# nvcr.io/nvidia/cloud-native/dcgm:3.1.8-1-ubuntu20.04
# nvcr.io/nvidia/k8s/dcgm-exporter:3.1.8-3.1.5-ubuntu20.04
# nvcr.io/nvidia/kubevirt-gpu-device-plugin:v1.2.2 
# registry.k8s.io/nfd/node-feature-discovery-operator:latest 
# registry.k8s.io/nfd/node-feature-discovery-operator:v0.6.0 
# registry.k8s.io/nfd/node-feature-discovery:v0.12.1 
# registry.k8s.io/coredns/coredns:v1.9.3
# registry.k8s.io/etcd:3.5.6-0
# registry.k8s.io/kube-apiserver:v1.25.12
# registry.k8s.io/kube-controller-manager:v1.25.12
# registry.k8s.io/kube-proxy:v1.25.12
# registry.k8s.io/kube-scheduler:v1.25.12
# registry.k8s.io/pause:3.8


## Download Kubernetes 1.25
mkdir -p 03_kubernetes
sudo mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

# sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# # echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-bionic main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install --reinstall -y kubelet=1.25.12-00 kubeadm=1.25.12-00 kubectl=1.25.12-00 --download-only
sudo mv /var/cache/apt/archives/*.deb 03_kubernetes/
sudo apt-get install --reinstall -y kubelet=1.25.12-00 kubeadm=1.25.12-00 kubectl=1.25.12-00
sudo rm /var/cache/apt/archives/*.deb


STOPED HERER



To add https://github.com/kubernetes-sigs/metrics-server

## Download docker images
mkdir -p 05_dockerimages
kubeadm config images pull

Dunno pull until where. Think need to configure containd with kubeadm first
# [config/images] Pulled registry.k8s.io/kube-apiserver:v1.25.12
# [config/images] Pulled registry.k8s.io/kube-controller-manager:v1.25.12
# [config/images] Pulled registry.k8s.io/kube-scheduler:v1.25.12
# [config/images] Pulled registry.k8s.io/kube-proxy:v1.25.12
# [config/images] Pulled registry.k8s.io/pause:3.8
# [config/images] Pulled registry.k8s.io/etcd:3.5.6-0
# [config/images] Pulled registry.k8s.io/coredns/coredns:v1.9.3

stopped here.

docker pull k8s.gcr.io/kube-proxy:v1.25.12
docker pull quay.io/coreos/flannel:v0.13.1-rc1
docker pull nvidia/k8s-device-plugin:v0.7.3
echo Saving images to file
sudo docker save $(sudo docker images | sed '1d' | awk '{print $1 ":" $2 }') -o 05_dockerimages/k8simages.tar
## Download/Create config files
mkdir -p 06_config
wget https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.7.3/nvidia-device-plugin.yml
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
mv nvidia-device-plugin.yml 06_config
mv kube-flannel.yml 06_config
