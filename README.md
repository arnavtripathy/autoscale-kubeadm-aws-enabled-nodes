# autoscale-kubeadm-aws-enabled-nodes

A small bash script I wrote which you can add as user data script for autoscaling group . Using this, whenever the certain metrics of ASG are met, automatically a new node is added. It's only for AWS enabled kubeadm clusters. There are some conditions added which would label node as per node type
