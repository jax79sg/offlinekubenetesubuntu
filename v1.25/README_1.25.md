Setting up Kubernetes has been made simple nowadays, but that mostly requires an active Internet connection. What happens when we need to do this in an offline environment? We can do this, but would require an additional machine/vm that's connected to the Internet. 

This article is inspired from https://ahmermansoor.blogspot.com/2019/04/install-kubernetes-k8s-offline-on-centos-7.html . The main difference is that this is specifically for *Ubuntu*.

# The following will be setup after all is done.
## Online environment
* Internet machine
   * A freshly installed Ubuntu 18.04.06, do not run any apt commands after fresh install.
   * This can be a virtual machine. 
   * It will be used to download all the necessary tools

## Offline environment
* Master node
   * Ubuntu 18.04.06. 
   * Can be a virtual machine
* Worker node (CPU)
   * Ubuntu 18.04.06. 
   * Can be a virtual machine
* Worker node (GPU/CPU)
   * Ubuntu 18.04.06. 
   * Can be a virtual machine
-----
# Setting up the Internet machine
The following script will attempt to download and create all the necessary dependancies and configuration for transfer to the offline master node.
```
sudo apt update
sudo apt install -y git
git clone https://github.com/jax79sg/offlinekubenetesubuntu
cd offlinekubenetesubuntu/v1.25
chmod +x 01-download-essentials.sh
sudo ./01-download-essentials.sh
```

Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
Copy the `offlinekubenetesubuntu/v1.19` folder to `mnt/usbdrive` and transfer the content to the offline Kubernetes Master.

The script of `01-download-essentials.sh` is as follows.
```
#!/bin/bash
set -x
# keep track of the last executed command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

## Download essentials
mkdir -p 01_essentials
sudo apt update
sudo apt-get install --reinstall -y liberror-perl git-man git vim net-tools build-essential openssh-server apt-transport-https curl --download-only
sudo mv /var/cache/apt/archives/*.deb 01_essentials/
sudo apt-get install --reinstall -y liberror-perl git-man git vim net-tools build-essential openssh-server apt-transport-https curl
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
docker pull k8s.gcr.io/kube-proxy:v1.19.6
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
```
      
-----
# Setting up the offline Kubernetes Master machine
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
* Setting up the network<br>
    * Make sure that only one network adaptor is active<br>
    * You can find out your IP and Interface by running `ip addr`<br>
    ```
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
    2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:ed:d1:69 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.109/24 brd 192.168.56.255 scope global dynamic noprefixroute enp0s3
       valid_lft 567sec preferred_lft 567sec
    inet6 fe80::7585:cba2:21f7:4f1c/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
    ```
    * Assuming the IP is ```192.168.56.109/24``` and its interface name is `enp0s3`<br><br>
    * Note: IP address should be static<br>
    * Setup the `/etc/netplan/01-network-manager-all.yaml` file as follows<br>
    ```
    network:
    version: 2
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: no
            dhcp6: no
            addresses: [192.168.56.109/24]
            gateway4: 192.168.56.102
    ```
* Copy all on usb drive to current working directory
   `cp -r /mnt/usbdrive/* .`<br>
* Install deb files<br>
   ```
   sudo dpkg -i 01_essentials/*.deb. #Do this multiple times till no errors
   sudo dpkg -i 03_kubernetes/*.deb. #Do this multiple times till no errors
   sudo dpkg -i 04_nvidiadocker/*.deb. #Do this multiple times till no errors   
   ```
* Install docker<br>
   ```
   tar -xvf 02_docker/docker-18.03.9.tgz
   sudo cp docker/* /usr/bin/
   sudo cp 02_docker/docker.service /etc/systemd/system/
   sudo chmod 644 /etc/systemd/system/docker.service
   sudo systemctl enable docker
   sudo systemctl restart docker
   sudo groupadd docker
   sudo usermod -aG docker $USER
   newgrp docker
   ```

* Install docker images<br>
   ```
   sudo docker load -i 05_dockerimages/dockerimages.tar
   ```
   
* Disable swap<br>
   ```
   sudo swapoff -a
   sudo sed -e '/swap/s/^/#/g' -i /etc/fstab
   ```
   
* Install Kubernetes master<br>
   `sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.56.109` <br>
   After some time you should receive a message saying master node successfully installed. Do copy down the instructions to add worker nodes.It looks something like below<br>
   ```
   kubeadm join 192.168.56.109:6443 --token pju168.rh6ww8rovsopr5dr \
    --discovery-token-ca-cert-hash sha256:ab423d13e9e6c0dcb1850b1cdd0e106376b6f9df85d5de39f4016c66f8fa1b42
   ```
   NOTE: If you don't have above info, simply run `kubeadm token create --print-join-command` on the master node.<br>
   Perform after actions<br>
   ``` 
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```
   <br>
   
   Remove master taint <br>
   `kubectl taint nodes --all node-role.kubernetes.io/master-`

   Install flannel network<br>
   `kubectl apply -f kube-flannel.yml`<br>
   
   
* Check installation<br>
   `kubectl get nodes`<br>
   You should see a status indicating master node is ready.
-----
# Setting up the offline Kubernetes Worker (CPU) machine
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
* Setting up the network<br>
    * Make sure that only one network adaptor is active<br>
    * You can find out your IP and Interface by running `ip addr`<br>
    ```
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
    2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:ed:d1:69 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.109/24 brd 192.168.56.255 scope global dynamic noprefixroute enp0s3
       valid_lft 567sec preferred_lft 567sec
    inet6 fe80::7585:cba2:21f7:4f1c/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
    ```
    * Assuming the IP is ```192.168.56.109/24``` and its interface name is `enp0s3`<br><br>
    * Note: IP address should be static<br>
    * Setup the `/etc/netplan/01-network-manager-all.yaml` file as follows<br>
    ```
    network:
    version: 2
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: no
            dhcp6: no
            addresses: [192.168.56.109/24]
            gateway4: 192.168.56.102
    ```
    
* Copy all on usb drive to current working directory
   `cp -r /mnt/usbdrive/* .`<br>
* Install deb files<br>
   ```
   sudo dpkg -i 01_essentials/*.deb. #Do this multiple times till no errors
   sudo dpkg -i 03_kubernetes/*.deb. #Do this multiple times till no errors
   sudo dpkg -i 04_nvidiadocker/*.deb. #Do this multiple times till no errors   
   ```
* Install docker<br>
   ```
   tar -xvf 02_docker/docker-18.03.9.tgz
   sudo cp docker/* /usr/bin/
   sudo cp 02_docker/docker.service /etc/systemd/system/
   sudo chmod 644 /etc/systemd/system/docker.service
   sudo systemctl enable docker
   sudo systemctl restart docker
   sudo groupadd docker
   sudo usermod -aG docker $USER
   newgrp docker
   ```

* Install docker images<br>
   ```
   sudo docker load -i 05_dockerimages/dockerimages.tar
   ```
   
* Disable swap<br>
   ```
   sudo swapoff -a
   sudo sed -e '/swap/s/^/#/g' -i /etc/fstab
   ```
   
* Join Kubenetes cluster by pasting the instructions from the master of joining the node. It looks something like below.<br>
    ```
    kubeadm join 192.168.56.109:6443 --token pju168.rh6ww8rovsopr5dr \
    --discovery-token-ca-cert-hash sha256:ab423d13e9e6c0dcb1850b1cdd0e106376b6f9df85d5de39f4016c66f8fa1b42
    ```
* Go to master node and run following<br>
   `kubectl get nodes`<br>
   You should see 2 nodes that are ready.
   
-----
# Setting up the offline Kubernetes Worker (GPU/CPU) machine   
Assuming that the nvidia-driver is installed and `nvidia-smi` is functional. (See https://www.nvidia.com/Download/index.aspx?lang=en-us)
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
* Setting up the network<br>
    * Make sure that only one network adaptor is active<br>
    * You can find out your IP and Interface by running `ip addr`<br>
    ```
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
    2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:ed:d1:69 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.109/24 brd 192.168.56.255 scope global dynamic noprefixroute enp0s3
       valid_lft 567sec preferred_lft 567sec
    inet6 fe80::7585:cba2:21f7:4f1c/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
    ```
    * Assuming the IP is ```192.168.56.109/24``` and its interface name is `enp0s3`<br><br>
    * Note: IP address should be static<br>
    * Setup the `/etc/netplan/01-network-manager-all.yaml` file as follows<br>
    ```
    network:
    version: 2
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: no
            dhcp6: no
            addresses: [192.168.56.109/24]
            gateway4: 192.168.56.102
    ```
    
* Copy all on usb drive to current working directory
   `cp -r /mnt/usbdrive/* .`<br>
* Install deb files<br>
   ```
   sudo dpkg -i 01_essentials/*.deb. #Do this multiple times till no errors
   sudo dpkg -i 03_kubernetes/*.deb. #Do this multiple times till no errors
   sudo dpkg -i 04_nvidiadocker/*.deb. #Do this multiple times till no errors   
   ```
* Install docker<br>
   ```
   tar -xvf 02_docker/docker-18.03.9.tgz
   sudo cp docker/* /usr/bin/
   sudo cp 02_docker/docker.service /etc/systemd/system/
   sudo chmod 644 /etc/systemd/system/docker.service
   sudo systemctl enable docker
   sudo systemctl restart docker
   sudo groupadd docker
   sudo usermod -aG docker $USER
   newgrp docker
   ```

* Install docker images<br>
   ```
   sudo docker load -i 05_dockerimages/dockerimages.tar
   ```
   
* Disable swap<br>
   ```
   sudo swapoff -a
   sudo sed -e '/swap/s/^/#/g' -i /etc/fstab
   ```
   
* Join Kubenetes cluster by pasting the instructions from the master of joining the node. It looks something like below.<br>
   ```
    kubeadm join 192.168.56.109:6443 --token pju168.rh6ww8rovsopr5dr \
    --discovery-token-ca-cert-hash sha256:ab423d13e9e6c0dcb1850b1cdd0e106376b6f9df85d5de39f4016c66f8fa1b42
    ```
   NOTE: If you don't have above info, simply run `kubeadm token create --print-join-command` on the master node.<br>
   
* Go to master node and run following<br>
   ```kubectl get nodes```<br>
   You should see 2 nodes that are ready.
   
* Install nvidia-docker-2<br>
   ```
   cp -r /mnt/usbdrive/nvidia-docker-2
   sudo dpkg -i /mnt/usbdrive/nvidia-docker-2/*.deb
   sudo systemctl restart docker
   ```
   
   You will need to enable the nvidia runtime as your default runtime on your GPU node. Editing the docker daemon config file which is usually present at 
   ```
   /etc/docker/daemon.json:
   {
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "default-runtime": "nvidia",
    "default-ulimits": {
        "nofile": {
            "name": "nofile",
            "hard": 65536,
            "soft": 1024
        },
        "memlock":
        {
            "name": "memlock",
            "soft": -1,
            "hard": -1
        }
    }
   }

         
   ```
* Install the nvidia daemonset
  `kubectl apply -f 06_config/nvidia-device-plugin.yml`
 
   Reboot the GPU computer
 * Go back to Master node and run the follwing command <br>
    `kubectl describe nodes | grep -i nvidia.com` <br>
    You should see something like nvidia.com/gpu: N, where N represents the number of GPUs on that node.
