#!/bin/bash
sudo hostnamectl set-hostname  $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
MASTER_IP=#Put Master node IP
KUBEADM_TOKEN=$(ssh ubuntu@${MASTER_IP} -i /home/ubuntu/.ssh/id_rsa -t -t -o StrictHostKeyChecking=no "sudo kubeadm token create")
KUBEADM_CONF=/home/ubuntu/kubeadm-join-config.conf
K8S_API_ENDPOINT_INTERNAL="${MASTER_IP}:6443"
CA_CERT_HASH=$(ssh ubuntu@${MASTER_IP} -i /home/ubuntu/.ssh/id_rsa -t -t -o StrictHostKeyChecking=no "sudo openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1")
HOSTNAME=$(hostname)
bash -c "cat <<EOF >${KUBEADM_CONF}
apiVersion: kubeadm.k8s.io/v1beta2
caCertPath: /etc/kubernetes/pki/ca.crt
discovery:
  bootstrapToken:
    apiServerEndpoint: ${K8S_API_ENDPOINT_INTERNAL}
    caCertHashes:
    - sha256:${CA_CERT_HASH}
    token: ${KUBEADM_TOKEN}
  timeout: 5m0s
  tlsBootstrapToken: ${KUBEADM_TOKEN}
kind: JoinConfiguration
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  kubeletExtraArgs:
    cloud-provider: aws
  name: ${HOSTNAME}
  taints: null
"
sudo kubeadm join --config ${KUBEADM_CONF}


INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
HOSTNAME=$(hostname)
C5REGEX="c5*"
R5REGEX="r5*"
ssh ubuntu@${MASTER_IP} -i /home/ubuntu/.ssh/id_rsa -t -t -o StrictHostKeyChecking=no "kubectl label nodes ${HOSTNAME}  tag-"
if [[ "${INSTANCE_TYPE}" =~ $C5REGEX ]]
then
    ssh ubuntu@${MASTER_IP} -i /home/ubuntu/.ssh/id_rsa -t -t -o StrictHostKeyChecking=no "sudo kubectl label nodes ${HOSTNAME}  node-kube=compute stateful=false"
    
elif [[ "${INSTANCE_TYPE}" =~ $R5REGEX ]]
then
  ssh ubuntu@${MASTER_IP} -i /home/ubuntu/.ssh/id_rsa -t -t -o StrictHostKeyChecking=no "sudo kubectl label nodes ${HOSTNAME}  node-kube=memory stateful=false"
else
  ssh ubuntu@${MASTER_IP} -i /home/ubuntu/.ssh/id_rsa -t -t -o StrictHostKeyChecking=no "sudo kubectl label nodes ${HOSTNAME} node-kube=general stateful=false"
fi
