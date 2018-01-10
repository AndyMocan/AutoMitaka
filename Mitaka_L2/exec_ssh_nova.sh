#!/bin/bash


yum install expect -y
cp /root/openstack-mitaka/compute_ip /var/lib/nova/openstack-mitaka/compute_ip
cp /root/openstack-mitaka/ssh_trust.sh /var/lib/nova/openstack-mitaka/
chmod -R 777 /var/lib/nova/openstack-mitaka
cat /var/lib/nova/openstack-mitaka/compute_ip  | awk -F '=' '{print $2}' > /var/lib/nova/openstack-mitaka/compute_host_file

#bash /var/lib/nova/ssh_trust.sh nova nova /var/lib/nova/openstack-mitaka/compute_host_file


