#!/bin/bash
source /root/openstack-mitaka/controller_ip
pcs resource restart haproxy-clone
mysql -uroot -proot1234 -hcontroller mysql -e "CREATE DATABASE keystone;"



token_temp=`openssl rand -hex 10`


openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $token_temp
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://root:root1234@controller/keystone

openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_host controller:5672
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_durable_queues true

# 拷贝配置keystone配置文件
/root/openstack-mitaka/expect_scp.sh /etc/keystone/keystone.conf controller02 /etc/keystone/keystone.conf
/root/openstack-mitaka/expect_scp.sh /etc/keystone/keystone.conf controller03 /etc/keystone/keystone.conf


# 配置haproxy
grep "keystone_admin_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then

    echo "
listen keystone_admin_cluster
    bind $controller:35357
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:35357 check inter 2000 rise 2 fall 5
    server controller02 $controller02:35357 check inter 2000 rise 2 fall 5
    server controller03 $controller03:35357 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

grep "keystone_public_internal_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then

    echo "
listen keystone_public_internal_cluster
    bind $controller:5000
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:5000 check inter 2000 rise 2 fall 5
    server controller02 $controller02:5000 check inter 2000 rise 2 fall 5
    server controller03 $controller03:5000 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

# 拷贝至其他控制节点
/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller02 /etc/haproxy/haproxy.cfg
/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller03 /etc/haproxy/haproxy.cfg

pcs resource restart haproxy-clone

su -s /bin/sh -c "keystone-manage db_sync" keystone

pcs resource create  openstack-keystone systemd:httpd --clone interleave=true
pcs resource restart openstack-keystone-clone
if [ $? != 0 ];then
    exit 1
fi
echo "
export OS_TOKEN=$token_temp
export OS_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
" > /root/temp_token.sh

source /root/temp_token.sh
pcs resource restart openstack-keystone-clone
if [ $? != 0 ];then
    exit 1
fi
openstack service list | grep keystone
if [ $? != 0 ];then
    openstack service create --name keystone --description "OpenStack Identity" identity
fi

openstack endpoint create --region RegionOne identity public http://controller:5000/v3
openstack endpoint create --region RegionOne identity internal http://controller:5000/v3
openstack endpoint create --region RegionOne identity admin http://controller:35357/v3

openstack domain create --description "Default Domain" default
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password admin admin
openstack role create admin
openstack role add --project admin --user admin admin

openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password demo demo
openstack role create user
openstack role add --project demo --user demo user


# 生成keystonerc_admin脚本
echo "export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=admin
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \W(keystone_admin)]\$ '
">/root/keystonerc_admin
chmod +x /root/keystonerc_admin

# 生成keystonerc_demo脚本
echo "export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=demo
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \W(keystone_admin)]\$ '
">/root/keystonerc_demo
chmod +x /root/keystonerc_demo

pcs resource restart openstack-keystone-clone
if [ $? != 0 ];then
    exit 1
fi

source /root/keystonerc_admin
### check
openstack token issue

source /root/keystonerc_demo
### check
openstack token issue