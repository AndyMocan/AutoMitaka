#!/bin/bash
yum install ntpdate -y
controller01_IP=`cat /root/openstack-mitaka/controller_ip | grep 'controller01' | awk -F '=' '{print $2}'`

echo "*/5 * * * * /usr/sbin/ntpdate $controller01_IP >/dev/null 2>&1" >> /var/spool/cron/root
/usr/sbin/ntpdate $controller01_IP

# 去除重复行（一般在重复执行脚本时会出现重复行）,必须经过root.bak文件中转一下
sort /var/spool/cron/root | uniq > /var/spool/cron/root.bak
cat /var/spool/cron/root.bak > /var/spool/cron/root
