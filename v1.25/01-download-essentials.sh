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
echo "cleanup completed"
read -p "Press any key to resume ...ctrl-c to quit"
## Download essentials
mkdir -p 01_essentials
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg --download-only
sudo mv /var/cache/apt/archives/*.deb 01_essentials/
sudo apt-get install -y ca-certificates curl gnupg
sudo apt update
sudo apt-get install --reinstall -y liberror-perl git-man git vim net-tools build-essential openssh-server apt-transport-https curl ca-certificates curl gnupg --download-only
sudo mv /var/cache/apt/archives/*.deb 01_essentials/
sudo apt-get install --reinstall -y liberror-perl git-man git vim net-tools build-essential openssh-server apt-transport-https curl ca-certificates curl gnupg
sudo rm /var/cache/apt/archives/*.deb
echo "apt stuff completed"
read -p "Press any key to resume ...ctrl-c to quit"


wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
sudo cp containerd.service /etc/systemd/system/containerd.service
sudo mkdir -p /etc/containerd
sudo cp config.toml /etc/containerd/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl start containerd
sudo mkdir -p /var/lib/containerd/
wget https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.3.0.tgz
wget https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz
tar -xvf nerdctl-1.5.0-linux-amd64.tar.gz
sudo cp nerdctl /usr/local/bin/
wget https://github.com/moby/buildkit/releases/download/v0.12.1/buildkit-v0.12.1.linux-amd64.tar.gz
tar -xvf buildkit-v0.12.1.linux-amd64.tar.gz
sudo mv bin/* /usr/local/bin/
sudo cp buildkit.service /etc/systemd/system/
sudo cp buildkit.socket /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now buildkit
sudo systemctl start buildkit
echo "Supporting K8S stuff completed"
read -p "Press any key to resume ...ctrl-c to quit"


###### Download following container images
sudo nerdctl pull nvcr.io/nvidia/cloud-native/gpu-operator-validator:latest
sudo nerdctl pull nvcr.io/nvidia/cloud-native/k8s-driver-manager:v0.6.2 
sudo nerdctl pull nvcr.io/nvidia/cloud-native/k8s-mig-manager:v0.5.3-ubuntu20.04
sudo nerdctl pull nvcr.io/nvidia/cloud-native/vgpu-device-manager:v0.2.3
sudo nerdctl pull nvcr.io/nvidia/cuda:12.2.0-base-ubi8 
sudo nerdctl pull nvcr.io/nvidia/driver:latest 
sudo nerdctl pull nvcr.io/nvidia/driver:535.86.10 
sudo nerdctl pull nvcr.io/nvidia/gpu-feature-discovery:v0.8.1-ubi8 
sudo nerdctl pull nvcr.io/nvidia/gpu-operator:latest 
sudo nerdctl pull nvcr.io/nvidia/k8s-device-plugin:v0.14.1-ubi8 
sudo nerdctl pull nvcr.io/nvidia/k8s/container-toolkit:v1.13.4-ubuntu20.04 
sudo nerdctl pull nvcr.io/nvidia/k8s/container-toolkit:latest 
sudo nerdctl pull nvcr.io/nvidia/cloud-native/dcgm:3.1.8-1-ubuntu20.04
sudo nerdctl pull nvcr.io/nvidia/k8s/dcgm-exporter:3.1.8-3.1.5-ubuntu20.04
sudo nerdctl pull nvcr.io/nvidia/kubevirt-gpu-device-plugin:v1.2.2 
sudo nerdctl pull registry.k8s.io/nfd/node-feature-discovery-operator:latest 
sudo nerdctl pull registry.k8s.io/nfd/node-feature-discovery-operator:v0.6.0 
sudo nerdctl pull registry.k8s.io/nfd/node-feature-discovery:v0.12.1 
sudo nerdctl pull registry.k8s.io/coredns/coredns:v1.9.3
sudo nerdctl pull registry.k8s.io/etcd:3.5.6-0
sudo nerdctl pull registry.k8s.io/kube-apiserver:v1.25.12
sudo nerdctl pull registry.k8s.io/kube-controller-manager:v1.25.12
sudo nerdctl pull registry.k8s.io/kube-proxy:v1.25.12
sudo nerdctl pull registry.k8s.io/kube-scheduler:v1.25.12
sudo nerdctl pull registry.k8s.io/pause:3.8
sudo nerdctl pull docker.io/flannel/flannel:v0.22.1
sudo nerdctl pull docker.io/flannel/flannel-cni-plugin:v1.2.0

echo "Image pulls complete"
read -p "Press any key to resume ...ctrl-c to quit"

git clone https://github.com/NVIDIA/gpu-operator
tar -xvf gpu-operator-v23.3.2.tgz

## Download Kubernetes 1.25
mkdir -p 03_kubernetes
sudo mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
sudo apt-get update
sudo apt-get install --reinstall -y kubelet=1.25.12-00 kubeadm=1.25.12-00 kubectl=1.25.12-00 --download-only
sudo mv /var/cache/apt/archives/*.deb 03_kubernetes/
sudo apt-get install --reinstall -y kubelet=1.25.12-00 kubeadm=1.25.12-00 kubectl=1.25.12-00
sudo rm /var/cache/apt/archives/*.deb


wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
git clone https://github.com/kubernetes-sigs/metrics-server


## Download docker images
mkdir -p 05_dockerimages/k8s.io
sudo kubeadm config images pull
echo "K8S stuff complete"
read -p "Press any key to resume ...ctrl-c to quit"


sudo nerdctl save nvcr.io/nvidia/cloud-native/gpu-operator-validator:latest -o gpu-operator-validator.tar
sudo nerdctl save nvcr.io/nvidia/cloud-native/k8s-driver-manager:v0.6.2 -o k8s-driver-manager.tar
sudo nerdctl save nvcr.io/nvidia/cloud-native/k8s-mig-manager:v0.5.3-ubuntu20.04 -o k8s-mig-manager.tar
sudo nerdctl save nvcr.io/nvidia/cloud-native/vgpu-device-manager:v0.2.3 -o vgpu-device-manager.tar
sudo nerdctl save nvcr.io/nvidia/cuda:12.2.0-base-ubi8 -o cuda.tar
sudo nerdctl save nvcr.io/nvidia/driver:latest -o driver.tar
sudo nerdctl save nvcr.io/nvidia/driver:535.86.10 -o driver-version.tar
sudo nerdctl save nvcr.io/nvidia/gpu-feature-discovery:v0.8.1-ubi8 -o gpu-feature-discovery.tar
sudo nerdctl save nvcr.io/nvidia/gpu-operator:latest -o gpu-operator.tar
sudo nerdctl save nvcr.io/nvidia/k8s-device-plugin:v0.14.1-ubi8 -o k8s-device-plugin.tar
sudo nerdctl save nvcr.io/nvidia/k8s/container-toolkit:v1.13.4-ubuntu20.04 -o container-toolkit.tar
sudo nerdctl save nvcr.io/nvidia/k8s/container-toolkit:latest -o container-toolkit-version.tar
sudo nerdctl save nvcr.io/nvidia/cloud-native/dcgm:3.1.8-1-ubuntu20.04 -o dcgm.tar
sudo nerdctl save nvcr.io/nvidia/k8s/dcgm-exporter:3.1.8-3.1.5-ubuntu20.04 -o dcgm-exporter.tar
sudo nerdctl save nvcr.io/nvidia/kubevirt-gpu-device-plugin:v1.2.2  -o kubevirt-gpu-device-plugin.tar
sudo nerdctl save registry.k8s.io/nfd/node-feature-discovery-operator:latest -o node-feature-discovery-operator.tar
sudo nerdctl save registry.k8s.io/nfd/node-feature-discovery-operator:v0.6.0 -o node-feature-discovery-operator-version.tar 
sudo nerdctl save registry.k8s.io/nfd/node-feature-discovery:v0.12.1  -o node-feature-discovery.tar
sudo nerdctl save -n k8s.io registry.k8s.io/coredns/coredns:v1.9.3 -o ./k8s.io/coredns.tar
sudo nerdctl save -n k8s.io registry.k8s.io/etcd:3.5.6-0 -o ./k8s.io/etcd.tar
sudo nerdctl save -n k8s.io registry.k8s.io/kube-apiserver:v1.25.12 -o ./k8s.io/kube-apiserver.tar
sudo nerdctl save -n k8s.io  registry.k8s.io/kube-controller-manager:v1.25.12 -o ./k8s.io/kube-controller-manager.tar
sudo nerdctl save -n k8s.io registry.k8s.io/kube-proxy:v1.25.12 -o ./k8s.io/kube-proxy.tar
sudo nerdctl save -n k8s.io registry.k8s.io/kube-scheduler:v1.25.12 -o ./k8s.io/kube-scheduler.tar
sudo nerdctl save -n k8s.io registry.k8s.io/pause:3.8 -o ./k8s.io/pause.tar
sudo nerdctl save docker.io/flannel/flannel:v0.22.1 -o flannel.tar
sudo nerdctl save docker.io/flannel/flannel-cni-plugin:v1.2.0 -o flannel-cni-plugin.tar
echo "Save images to disk ok"
read -p "Press any key to resume ...ctrl-c to quit"

