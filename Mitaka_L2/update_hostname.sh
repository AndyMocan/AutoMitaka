#!/bin/bash


data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
        hostnamectl set-hostname $hostname && hostname $hostname

    fi


done