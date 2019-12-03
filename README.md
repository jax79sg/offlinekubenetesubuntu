Setting up Kubernetes has been made simple nowadays, but that mostly requires an active Internet connection. What happens when we need to do this in an offline environment? We can do this, but would require an additional machine/vm that's connected to the Internet. 

This article is inspired from https://ahmermansoor.blogspot.com/2019/04/install-kubernetes-k8s-offline-on-centos-7.html . The main difference is that this is specifically for *Ubuntu*.

# The following will be setup after all is done.
## Online environment
* Internet machine
   * Ubuntu 18.04.03. 
   * This can be a virtual machine. 
   * Its used to download all the necessary tools

## Offline environment
* Master node
   * Ubuntu 18.04.03. 
   * Can be a virtual machine
* Worker node
   * Ubuntu 18.04.03. 
   * Can be a virtual machine

-----
# Setting up the Internet machine
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
* Clone the repo with the necessary scripts<br>
   ```git clone https://github.com/jax79sg/offlinekubenetesubuntu```<br>
   ```cp -r offlinekubenetesubuntu /mnt/usbdrive```
   ```cd offlinekubenetesubuntu```
* Get files for docker (Up to 18.09 for kubernetes compatibility)<br>
   ```wget https://download.docker.com/linux/static/stable/x86_64/docker-18.09.9.tgz```<br>
   ```cp docker-18.09.9.tgz /mnt/usbdrive```
* Get deb files for Kubernetes <br>
   ```sudo apt-get install -y build-essential openssh-server apt-transport-https curl --download-only```<br>
   ```curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add```<br>
   ```curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -```<br>
   ```cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list```<br>
   ```deb https://apt.kubernetes.io/ kubernetes-xenial main```<br>
   ```EOF```<br>
   ```sudo apt-get update```<br>
   ```sudo apt-get install -y kubelet kubeadm kubectl --download-only```<br>
   ```sudo cp /var/cache/apt/archives/*.deb /mnt/usbdrive```<br>
* Install docker 18.09<br>
   ```tar -xvf docker-18.09.9.tgz```<br>
   ```sudo cp docker/* /usr/bin/```<br>
   ```copy 02_docker/docker.service /etc/systemd/system/```<br>
   ```sudo chmod 644 /etc/systemd/system/docker.service```<br>
   ```sudo systemctl enable docker```<br>
   ```sudo systemctl restart docker```<br>
   ```sudo groupadd docker```<br>
   ```sudo usermod -aG docker $USER```<br>
   ```newgrp docker```<br>
* Pull relevant images<br>
   ```wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml```<br>
   ```kubeadm config images pull```<br>
      * Make sure all following is pulled by running ```docker images```, if its not, maually do it by running ```docker pull image```<br>
      ```k8s.gcr.io/kube-apiserver``` v1.16.3 <br>
      ```k8s.gcr.io/kube-proxy``` v1.16.3<br>
      ```k8s.gcr.io/kube-controller-manager``` v1.16.3<br>
      ```k8s.gcr.io/kube-scheduler``` v1.16.3<br>
      ```k8s.gcr.io/etcd``` 3.3.15-0<br>
      ```k8s.gcr.io/coredns``` 1.6.2<br>
      ```k8s.gcr.io/pause``` 3.1<br>
      ```quay.io/coreos/flannel``` v0.11.0-amd64<br>
* Save all pulled images<br>
   ```docker save $(docker images | sed '1d' | awk '{print $1 ":" $2 }') -o dockerimages.tar```<br>
   ```cp dockerimages.tar /mnt/usbdrive```<br>
      
-----
# Setting up the offline Kubernetes Master machine
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
Assuming that only one network adaptor is active and its subnet is ```192.168.50.*```<br>
* Copy all on usb drive to current working directory
   ```cp -r /mnt/usbdrive/* .```<br>
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
* Install deb files for Kubenetes<br>
   ```sudo dpkg -i *.deb```<br>
* Install docker images<br>
   ```docker load -i dockerimages.tar```<br>
* Disable swap<br>
   ```sudo swapoff -a```<br>
    ``sudo sed -e '/swap/s/^/#/g' -i /etc/fstab```<br>
* Add default route<br>
   ```sudo route add default gw 192.168.50.254```
* Install Kubernetes master<br>
   ```sudo kubeadm init```<br>
   After some time you should receive a message saying master node successfully installed. Do copy down the instructions to add worker nodes.<br>
   Perform after actions<br>
   ```mkdir -p $HOME/.kube```<br>
   ```sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config```<br>
   ```sudo chown $(id -u):$(id -g) $HOME/.kube/config```<br>
   ```kubectl apply -f kube-flannel.yml```<br>
* Check installation<br>
   ```kubectl get nodes```<br>
   You should see a status indicating master node is ready.
   
# Setting up the offline Kubernetes Worker machine
Assuming that the usb drive is mounted at ```/mnt/usbdrive```<br>
Assuming that only one network adaptor is active and its subnet is ```192.168.50.*```<br>
* Copy all on usb drive to current working directory
   ```cp -r /mnt/usbdrive/* .```<br>
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
* Install deb files for Kubenetes<br>
   ```sudo dpkg -i *.deb```<br>
* Install docker images<br>
   ```docker load -i dockerimages.tar```<br>
* Disable swap<br>
   ```sudo swapoff -a```<br>
    ``sudo sed -e '/swap/s/^/#/g' -i /etc/fstab```<br>
* Add default route<br>
   ```sudo route add default gw 192.168.50.254```<br>
* Join Kubenetes cluster by pasting the instructions from the master of joining the node<br>
* Go to master node and run following<br>
   ```kubectl get nodes```<br>
   You should see 2 nodes that are ready.
