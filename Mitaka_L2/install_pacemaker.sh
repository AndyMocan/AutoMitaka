#!/bin/bash

yum install -y pcs pacemaker corosync fence-agents-all resource-agents

echo "
totem {
version: 2
secauth: off
cluster_name: openstack-cluster
transport: udpu
}

nodelist {
  node {
        ring0_addr: controller01
        nodeid: 1
       }
  node {
        ring0_addr: controller02
        nodeid: 2
       }
  node {
        ring0_addr: controller03
        nodeid: 3
}
}

quorum {
provider: corosync_votequorum
two_node: 1
}

logging {
to_syslog: yes
}
" > /etc/corosync/corosync.conf

systemctl enable pcsd
systemctl start pcsd
echo hacluster | passwd --stdin hacluster
