Setting up Kubernetes has been made simple nowadays, but that mostly requires an active Internet connection. What happens when we need to do this in an offline environment? We can do this, but would require an additional machine/vm that's connected to the Internet. 

This article is inspired from https://ahmermansoor.blogspot.com/2019/04/install-kubernetes-k8s-offline-on-centos-7.html . The main difference is that this is specifically for *Ubuntu*.

# The following will be setup after all is done.
## Online environment
* Internet machine
   * A freshly installed Ubuntu 18.04.05, do not run any apt commands after fresh install.
   * This can be a virtual machine. 
   * It will be used to download all the necessary tools

## Offline environment
* Master node
   * Ubuntu 18.04.05. 
   * Can be a virtual machine
* Worker node (CPU)
   * Ubuntu 18.04.05. 
   * Can be a virtual machine
* Worker node (GPU/CPU)
   * Ubuntu 18.04.05. 
   * Can be a virtual machine
-----
# Setting up the Internet machine
The following script will attempt to download and create all the necessary dependancies and configuration for transfer to the offline master node.
```
sudo apt update
sudo apt install -y git
git clone https://github.com/jax79sg/offlinekubenetesubuntu
cd offlinekubenetesubuntu/v1.19
chmod +x 01-download-essentials.sh
sudo ./01-download-essentials.sh
sudo ./01-download-essentials.sh #Yes, need to run twice to completion
```

Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
Copy the `offlinekubenetesubuntu/v1.19` folder to `mnt/usbdrive` and transfer the content to the offline Kubernetes Master.
      
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
   ```<br>

* Install docker images<br>
   ```
   docker load -i 05_dockerimages/dockerimages.tar
   ```<br>
* Disable swap<br>
   ```
   sudo swapoff -a
   sudo sed -e '/swap/s/^/#/g' -i /etc/fstab
   ```<br>
* Install Kubernetes master<br>
   `sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.56.109` <br>
   After some time you should receive a message saying master node successfully installed. Do copy down the instructions to add worker nodes.It looks something like below<br>
   ```
   kubeadm join 192.168.56.109:6443 --token 6ld0m1.y3abcy4ypbhgr2ep \
    --discovery-token-ca-cert-hash sha256:e01dba33f3808f5a847665e7e60b845fbe9940abb15b1692a8c9361137872d98
   ```
   NOTE: If you don't have above info, simply run `kubeadm token create --print-join-command` on the master node.<br>
   Perform after actions<br>
   ``` 
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```<br>
   
   Install flannel network<br>
   
   `kubectl apply -f kube-flannel.yml`<br>
   
* Check installation<br>
   `kubectl get nodes`<br>
   You should see a status indicating master node is ready.
-----
# Setting up the offline Kubernetes Worker (CPU) machine
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
* Setting up the network<br>
    * Assuming that only one network adaptor is active, its subnet is ```192.168.50.*``` and its interface name is `eth0`<br>
    * Note: IP address should be static<br>
    * Setup the `/etc/network/interfaces` file as follows<br>
    `# The loopback network interface`<br>
    `auto lo`<br>
    `iface lo inet loopback`<br>
    <br>`# The primary network interface`<br>
    `auto eth0`<br>
    `iface eth0 inet static`<br>
    `address 192.168.50.3`<br>
    `netmask 255.255.255.0`<br>
    `gateway 192.168.50.254`<br>
* Copy all on usb drive to current working directory
   ```cp -r /mnt/usbdrive/* .```<br>
* Install deb files for Kubenetes<br>
   ```sudo dpkg -i *.deb```<br>
* Install docker<br>
   ```tar -xvf docker-18.09.9.tgz```<br>
   ```sudo cp docker/* /usr/bin/```<br>
   ```copy 02_docker/docker.service /etc/systemd/system/```<br>
   ```sudo chmod 644 /etc/systemd/system/docker.service```<br>
   ```sudo systemctl enable docker```<br>
   ```sudo systemctl restart docker```<br>
   ```sudo groupadd docker```<br>
   ```sudo usermod -aG docker $USER```<br>
   ```newgrp docker```<br>

* Install docker images<br>
   ```docker load -i dockerimages.tar```<br>
* Disable swap<br>
   ```sudo swapoff -a```<br>
    ``sudo sed -e '/swap/s/^/#/g' -i /etc/fstab```<br>
~~* Add default route<br>~~
   ~~```sudo route add default gw 192.168.50.254```<br>~~
* Join Kubenetes cluster by pasting the instructions from the master of joining the node. It looks something like below.<br>
   ```kubeadm join 192.168.50.2:6443 --token 6e4ntu.a5r1md9vuqex4pe8 --discovery-token-ca-cert-hash sha256:19f4d9f6d433cc12addb70e2737c629213777deed28fa5dcc33f9d05d2382d5b```
* Go to master node and run following<br>
   ```kubectl get nodes```<br>
   You should see 2 nodes that are ready.
-----
# Setting up the offline Kubernetes Worker (GPU/CPU) machine   
Assuming that the nvidia-driver is installed and `nvidia-smi` is functional. (See https://www.nvidia.com/Download/index.aspx?lang=en-us)
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
* Setting up the network<br>
    * Assuming that only one network adaptor is active, its subnet is ```192.168.50.*``` and its interface name is `eth0`<br>
    * Note: IP address should be static<br>
    * Setup the `/etc/network/interfaces` file as follows<br>
    `# The loopback network interface`<br>
    `auto lo`<br>
    `iface lo inet loopback`<br>
    <br>`# The primary network interface`<br>
    `auto eth0`<br>
    `iface eth0 inet static`<br>
    `address 192.168.50.3`<br>
    `netmask 255.255.255.0`<br>
    `gateway 192.168.50.254`<br>
* Copy all on usb drive to current working directory
   ```cp -r /mnt/usbdrive/* .```<br>
* Install deb files for Kubenetes<br>
   ```sudo dpkg -i *.deb```<br>
* Install docker<br>
   ```tar -xvf docker-18.09.9.tgz```<br>
   ```sudo cp docker/* /usr/bin/```<br>
   ```copy 02_docker/docker.service /etc/systemd/system/```<br>
   ```sudo chmod 644 /etc/systemd/system/docker.service```<br>
   ```sudo systemctl enable docker```<br>
   ```sudo systemctl restart docker```<br>
   ```sudo groupadd docker```<br>
   ```sudo usermod -aG docker $USER```<br>
   ```newgrp docker```<br>

* Install docker images<br>
   ```docker load -i dockerimages.tar```<br>
* Disable swap<br>
   ```sudo swapoff -a```<br>
    ``sudo sed -e '/swap/s/^/#/g' -i /etc/fstab```<br>
~~* Add default route<br>~~
   ~~```sudo route add default gw 192.168.50.254```<br>~~
* Join Kubenetes cluster by pasting the instructions from the master of joining the node. It looks something like below.<br>
   ```kubeadm join 192.168.50.2:6443 --token 6e4ntu.a5r1md9vuqex4pe8 --discovery-token-ca-cert-hash sha256:19f4d9f6d433cc12addb70e2737c629213777deed28fa5dcc33f9d05d2382d5b```
   NOTE: If you don't have above info, simply run `kubeadm token create --print-join-command` on the master node.<br>
* Go to master node and run following<br>
   ```kubectl get nodes```<br>
   You should see 2 nodes that are ready.
* Install nvidia-docker-2<br>
   ```cp -r /mnt/usbdrive/nvidia-docker-2 .```<br>
   ```sudo dpkg -i /mnt/usbdrive/nvidia-docker-2/*.deb```<br>
   `sudo systemctl restart docker`<br>
   You will need to enable the nvidia runtime as your default runtime on your GPU node. Editing the docker daemon config file which is usually present at `/etc/docker/daemon.json`:
`{`<br>
`    "default-runtime": "nvidia",`<br>
`    "runtimes": {`<br>
`       "nvidia": {`<br>
`                   "path": "/usr/bin/nvidia-container-runtime",`<br>
`                   "runtimeArgs": []`<br>
`                 }`<br>
`                }`<br>
`}`<br>
   Reboot the GPU computer
 * Go back to Master node and run the follwing command <br>
    `kubectl describe nodes | grep -i nvidia.com` <br>
    You should see something like nvidia.com/gpu: N, where N represents the number of GPUs on that node.
