#!/bin/bash

yum install rabbitmq-server -y

echo "
*       soft    nproc     65536
*       hard    nproc    65536
*       soft    nofile    65536
*       hard    nofile   65536
*              soft        stack       65536
*              hard        stack       65536
root       soft    nproc     unlimited
root       hard    nproc     unlimited
" >  /etc/security/limits.d/20-nproc.conf
ulimit -n 65535

sed -i '/Type=notify/a\LimitNOFILE=65535' /usr/lib/systemd/system/rabbitmq-server.service

data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
        grep "$host_ip" /etc/rabbitmq/rabbitmq.config
        if [ $? != 0 ];then
            sed -i "/Network Connectivity/a\{tcp_listeners, [{'$host_ip', 5672}]}" /etc/rabbitmq/rabbitmq.config
        fi

    fi


done

for i in `ps -ef | grep rabbitmq | awk -F ' ' '{print $2}'`;do kill -9 $i;done

systemctl daemon-reload
systemctl enable rabbitmq-server


