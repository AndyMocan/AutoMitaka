#!/bin/bash
yum install expect -y
cat /root/openstack-mitaka/controller_ip /root/openstack-mitaka/compute_ip | grep -v -w 'controller' | awk -F '=' '{print $2}' > /root/openstack-mitaka/host_file
bash /root/openstack-mitaka/ssh_trust.sh root root1234 /root/openstack-mitaka/host_file


