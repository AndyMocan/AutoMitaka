#!/bin/bash

yum install ntp -y
controller01_IP=`cat /root/openstack-mitaka/controller_ip | grep 'controller01' | awk -F '=' '{print $2}'`
controller01_host=`echo $controller01_IP | awk -F '.' '{print $1"."$2"."$3"."0}'`
mv /etc/ntp.conf /etc/ntp.conf.bak
cat > /etc/ntp.conf << EOF

restrict default nomodify notrap noquery
restrict 127.0.0.1
restrict 172.29.5.0 mask 255.255.255.0 nomodify
server	127.127.1.0
fudge	127.127.1.0 stratum 10
EOF

# sed单引号不能传递变量，双引号可以传递变量
sed -i "s@172.29.5.0@$controller01_host@g" /etc/ntp.conf
systemctl restart ntpd.service
sleep 1
systemctl restart ntpd.service
if [ $? != 0 ]; then
    exit 1
fi