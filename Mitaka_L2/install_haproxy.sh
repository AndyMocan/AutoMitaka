#!/bin/bash
source /root/openstack-mitaka/controller_ip
yum install -y haproxy
# [所有控制节点] 修改/etc/rsyslog.d/haproxy.conf文件
echo "
\$ModLoad imudp
\$UDPServerRun 514
local3.* /var/log/haproxy.log
&~ " > /etc/rsyslog.d/haproxy.conf


# [所有控制节点] 修改/etc/sysconfig/rsyslog文件
sed -i -e 's#SYSLOGD_OPTIONS=\"\"#SYSLOGD_OPTIONS=\"-c 2 -r -m 0\"#g' /etc/sysconfig/rsyslog

# [所有控制节点] 重启rsyslog服务
systemctl restart rsyslog

echo "
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log 127.0.0.1 local3
    chroot  /var/lib/haproxy
    daemon
    group  haproxy
    maxconn  4000
    pidfile  /var/run/haproxy.pid
    user  haproxy


#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    log  global
    maxconn  4000
    option  redispatch
    retries  3
    timeout  http-request 10s
    timeout  queue 1m
    timeout  connect 10s
    timeout  client 1m
    timeout  server 1m
    timeout  check 10s

" > /etc/haproxy/haproxy.cfg


grep "galera_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then

    echo "
listen galera_cluster
    bind $controller:3306
    mode tcp
    option  httpchk
    server controller01 $controller01:3306 check port 9200 inter 2000 rise 2 fall 5
    server controller02 $controller02:3306 check port 9200 backup inter 2000 rise 2 fall 5
    server controller03 $controller03:3306 check port 9200 backup inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg

fi



