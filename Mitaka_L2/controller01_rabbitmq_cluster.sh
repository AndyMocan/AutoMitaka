#!/bin/bash
source /root/openstack-mitaka/controller_ip
rabbitmqctl set_policy ha-all '^(?!amq\.).*' '{"ha-mode": "all"}'

rabbitmqctl add_user openstack 'root1234'

rabbitmqctl set_permissions openstack ".*" ".*" ".*"
rabbitmq-plugins enable rabbitmq_management
rabbitmqctl set_user_tags openstack administrator

grep "admin_stats" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then

echo "
listen admin_stats
        stats   enable
        bind    $controller:9000
        mode    http
        option  httplog
        log     global
        maxconn 10
        stats   refresh 30s
        stats   uri /admin
        stats   realm haproxy
        stats   auth haproxy:haproxy
        stats   hide-version
        stats   admin if TRUE

" >> /etc/haproxy/haproxy.cfg

fi

grep "rabbitmq_admin" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
    echo "
    #####################我把RabbitMQ的管理界面也放在HAProxy后面了###############################
listen rabbitmq_admin
    bind $controller:8004
    server controller01 $controller01:15672
    server controller02 $controller02:15672
    server controller03 $controller03:15672
    " >> /etc/haproxy/haproxy.cfg
fi

grep "rabbitmq_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
    echo "
 ####################################################################
listen rabbitmq_cluster
    bind $controller:5672
    option tcplog
    mode tcp
    timeout client  3h
    timeout server  3h
    option          clitcpka
    balance roundrobin      #负载均衡算法（#banlance roundrobin 轮询，balance source 保存session值，支持static-rr，leastconn，first，uri等参数）
    server   controller01 $controller01:5672 check inter 5s rise 2 fall 3   #check inter 2000 是检测心跳频率，rise 2是2次正确认为服务器可用，fall 3是3次失败认为服务器不可用
    server   controller02 $controller02:5672 check inter 5s rise 2 fall 3
    server   controller03 $controller03:5672 check inter 5s rise 2 fall 3
    " >> /etc/haproxy/haproxy.cfg
fi


/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller02 /etc/haproxy/haproxy.cfg
/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller03 /etc/haproxy/haproxy.cfg

pcs resource restart haproxy-clone