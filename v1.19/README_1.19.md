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
    * Assuming that only one network adaptor is active, its subnet is ```192.168.50.*``` and its interface name is `eth0`<br>
    * Note: IP address should be static<br>
    * Setup the `/etc/network/interfaces` file as follows<br>
    `# The loopback network interface`<br>
    `auto lo`<br>
    `iface lo inet loopback`<br>
    <br>`# The primary network interface`<br>
    `auto eth0`<br>
    `iface eth0 inet static`<br>
    `address 192.168.50.2`<br>
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
   ```sudo sed -e '/swap/s/^/#/g' -i /etc/fstab```<br>
* ~~Add default route>~~<br>
   ~~```sudo route add default gw 192.168.50.254 eth0```>>~~<br>
* Install Kubernetes master<br>
   ```sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<myipaddress>``` # Replace `<myipaddress>` with IP address of master node<br>
   After some time you should receive a message saying master node successfully installed. Do copy down the instructions to add worker nodes.It looks something like below<br>
   ```kubeadm join 192.168.50.2:6443 --token 6e4ntu.a5r1md9vuqex4pe8 --discovery-token-ca-cert-hash sha256:19f4d9f6d433cc12addb70e2737c629213777deed28fa5dcc33f9d05d2382d5b```
   NOTE: If you don't have above info, simply run `kubeadm token create --print-join-command` on the master node.<br>
   Perform after actions<br>
   ```mkdir -p $HOME/.kube```<br>
   ```sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config```<br>
   ```sudo chown $(id -u):$(id -g) $HOME/.kube/config```<br>
   
   Install flannel network<br>
   ```sed -i 's/- --iface-regex=192\\\.168\\\.50\\\.+/- --iface=<ipaddress_regex>/g' kube-flannel.yml``` #replace `<ipaddress_regex>` with actual IP segment in regex form<br>
   ```kubectl apply -f kube-flannel.yml```<br>
* Check installation<br>
   ```kubectl get nodes```<br>
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
