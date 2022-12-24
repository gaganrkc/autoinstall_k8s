# autoinstall_k8s
Autoinstall Kubernetes in master and worker nodes using passwordless ssh.

Before using this kindly ensure that you have added ssh key to the worker nodes send from master nodes.

Steps for ssh key generation and sending it to worker nodes:
#ssh-keygen -t rsa                 -> then enter, enter, enter
#ssh-copy-id userid@ip_of_worker_node
#ssh userid@ipofworkernode                -> To check if passwordless ssh is working or not

