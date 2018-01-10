#!/bin/bash
source /root/openstack-mitaka/controller_ip

yum install memcached python-memcached -y
data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
echo "
PORT='11211'
USER='memcached'
MAXCONN='1024'
CACHESIZE='64'
OPTIONS='-l $host_ip,::1'
" > /etc/sysconfig/memcached
    fi


done

systemctl enable memcached.service
systemctl start memcached.service


grep "memcached" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
    echo "
    #####################我把RabbitMQ的管理界面也放在HAProxy后面了###############################
listen memcached
    bind $controller:11211
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:11211
    server controller02 $controller02:11211
    server controller03 $controller03:11211
    " >> /etc/haproxy/haproxy.cfg
fi
#/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller02 /etc/haproxy/haproxy.cfg
#/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller03 /etc/haproxy/haproxy.cfg

