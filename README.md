INTERNET

1. Get files for docker (Up to 18.09 for kubernetes compatibility)
  1. wget [https://download.docker.com/linux/static/stable/x86\_64/docker-18.09.9.tgz](https://download.docker.com/linux/static/stable/x86_64/docker-18.09.9.tgz)

1. Get deb files for kubenetes
  1. Sudo apt-get install -y build-essential openssh-server apt-transport-https curl --download-only
  2. curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
  3. curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  4. cat \&lt;\&lt;EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
  5. deb https://apt.kubernetes.io/ kubernetes-xenial main
  6. EOF
  7. sudo apt-get update
  8. sudo apt-get install -y kubelet kubeadm kubectl --download-only
  9.
  10. for i in $(apt-cache depends kubelet | grep -E &#39;Depends|Recommends|Suggests&#39; | cut -d &#39;:&#39; -f 2,3 | sed -e s/&#39;\&lt;&#39;/&#39;&#39;/ -e s/&#39;\&gt;&#39;/&#39;&#39;/); do sudo apt-get download $i 2\&gt;\&gt;errors.txt; done
  11. for i in $(apt-cache depends kubectl | grep -E &#39;Depends|Recommends|Suggests&#39; | cut -d &#39;:&#39; -f 2,3 | sed -e s/&#39;\&lt;&#39;/&#39;&#39;/ -e s/&#39;\&gt;&#39;/&#39;&#39;/); do sudo apt-get download $i 2\&gt;\&gt;errors.txt; done
  12. for i in $(apt-cache depends kubeadm | grep -E &#39;Depends|Recommends|Suggests&#39; | cut -d &#39;:&#39; -f 2,3 | sed -e s/&#39;\&lt;&#39;/&#39;&#39;/ -e s/&#39;\&gt;&#39;/&#39;&#39;/); do sudo apt-get download $i 2\&gt;\&gt;errors.txt; done
  13. Copy all files in /var/cache/apt/archives
2. Pull relevant images
  1. wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  2. kubeadm config images pull
    1. Make sure all following is pulled
    2. k8s.gcr.io/kube-apiserver                v1.16.3
    3. k8s.gcr.io/kube-proxy                    v1.16.3
    4. k8s.gcr.io/kube-controller-manager   v1.16.3
    5. k8s.gcr.io/kube-scheduler                v1.16.3
    6. k8s.gcr.io/etcd                          3.3.15-0
    7. k8s.gcr.io/coredns                       1.6.2
    8. k8s.gcr.io/pause                         3.1
    9. quay.io/coreos/flannel                   v0.11.0-amd64
  3. Save all docker images
    1. docker save $(docker images | sed &#39;1d&#39; | awk &#39;{print $1 &quot;:&quot; $2 }&#39;) -o dockerimages.tar



OFFLINE (Transfer all from internet)

1. Install docker
  1. Tar -xvf docker-18.09.9.tgz
  2. sudo cp docker/\* /usr/bin/
  3. Copy docker.service /etc/systemd/system/
  4. sudo chmod 644 /etc/systemd/system/docker.service
  5. ~~Mkdir /etc/docker
  6. ~~Copy daemon.json to /etc/docker/
  7. Sudo systemctl enable docker
  8. Sudo systemctl restart docker
  9. sudo groupadd docker
  10. sudo usermod -aG docker $USER
  11. newgrp docker
  12.
2.
3. Install deb files for kubenetes
  1. Sudo dpkg -i \*.deb
4. Install docker images
  1. docker load -i dockerimages.tar
5. Install kube
  ~~1. Sudo cp etc.default.kubelet /etc/default/kublet
  2. Sudo systemctl daemon-reload
  ~~3. Sudo systemctl restart kubelet
  4.
  5. Sudo cp etc\_sysctl.d\_kubernetes.conf /etc/sysctl.d
  ~~6. modprobe br\_netfilter
  7. Sudo sysctl --system
  8. Sudo swapoff -a
  9. Sudo sed -e &#39;/swap/s/^/#/g&#39; -i /etc/fstab
  10. source \&lt;(kubectl completion bash)
  11. sudo cp etc.bash\_completion.d\_kubectl /etc/bash\_completion.d/kubectl
  12. Sudo docker load -i dockerimages.tar
  13. sudo route add default gw 192.168.56.254
  14. Sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --v=8
  15. .mkdir -p $HOME/.kube
  16.   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  17.   sudo chown $(id -u):$(id -g) $HOME/.kube/config
  18. kubectl apply -f kube-flannel.yml
  19.
