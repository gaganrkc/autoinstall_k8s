#! /bin/bash

# perform steps before using bash
# ssh-keygen -t rsa                 -> then enter, enter, enter
# ssh-copy-id root@192.168.80.154
# ssh 'root@192.168.80.154'

function teedef(){
tee -a /etc/hosts << EOF
$1
EOF
}

echo "|----------------------------------------------------------------|"
echo "|                                                                |"
echo "|                 Script to make a k8s cluster                   |"
echo "|								 |"
echo "|----------------------------------------------------------------|"
echo ""

read -p "Type 'y' or 'Y' if you have passed the ssh key to the designated nodes, otherwise type 'n' or 'N' : " choice

case $choice in
                "y"|"Y")
                        echo "You have shared the ssh key."
                        ;;
                "n"|"N")
                        echo "You have not shared the ssh key. KIndly share the key with selected nodes."
			echo "Kindly perform the following commands for the worker nodes."
			echo "ssh-keygen -t rsa"
			echo "ssh-copy-id userid@IpOfWorkerNode"
			echo "ssh 'userid@IpOfWorkerNode'"
			exit 0
                        ;;
                *)
                        printf "Invalid Input\n"
			exit 0
                        ;;
esac

declare -a ips
declare -a hostnm
declare -a usr
read -p "No. of nodes you want to add in a cluster: " a

masterip=$(ifconfig ens33 | grep inet | head -n 1 | awk '{print $2}')
masterhstname=$(hostname)

teedef "$masterip	$masterhstname"


for((i=0 ; i < a ; i++))
do
	echo ""
	read -p "Enter the ip address of node $((i+1)): " ips[$i]
	read -p "Enter the hostname of node $((i+1)): " hostnm[$i]
	read -p "Enter the user id of node $((i+1)): " usr[$i]
	teedef "${ips[$i]}	${hostnm[$i]}"
	scp common_script.sh ${usr[$i]}@${ips[$i]}:/tmp/
	ssh ${usr[$i]}@${ips[$i]} "bash /tmp/common_script.sh"
done
echo "sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"
echo "sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"
bash common_script.sh
kubeadm config images pull

#########
firewall-cmd --add-port=6443/tcp --permanent
firewall-cmd --add-port=10250/tcp --permanent
firewall-cmd --reload
modprobe overlay
modprobe br_netfilter
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
########################
systemctl disable firewalld
kubeadm init > /tmp/output.txt
cat /tmp/output.txt | tail -n 2 > join-token

for((i=0 ; i < a ; i++))
do
	scp join-token ${usr[$i]}@${ips[$i]}:/tmp/
	ssh ${usr[$i]}@${ips[$i]} "./tmp/join-token"
done


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
