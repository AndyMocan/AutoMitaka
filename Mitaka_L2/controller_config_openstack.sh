#!/bin/bash


# 创建数据库
mysql -uroot -proot1234 -hcontroller mysql -e "CREATE DATABASE glance;"
mysql -uroot -proot1234 -hcontroller mysql -e "CREATE DATABASE nova;"
mysql -uroot -proot1234 -hcontroller mysql -e "CREATE DATABASE nova_api;"
mysql -uroot -proot1234 -hcontroller mysql -e "CREATE DATABASE neutron;"
mysql -uroot -proot1234 -hcontroller mysql -e "CREATE DATABASE cinder;"

# 创建资源
source /root/keystonerc_admin

# glance resource
openstack user create --domain default --password glance glance
openstack role add --project service --user glance admin
openstack service list | grep glance
if [ $? != 0 ];then
    openstack service create --name glance --description "OpenStack Image" image
fi
openstack endpoint list | grep image
if [ $? != 0 ];then
    openstack endpoint create --region RegionOne image public http://controller:9292
    openstack endpoint create --region RegionOne image internal http://controller:9292
    openstack endpoint create --region RegionOne image admin http://controller:9292
fi

# nova resource
openstack user create --domain default --password nova nova
openstack role add --project service --user nova admin
openstack service list | grep nova
if [ $? != 0 ];then
    openstack service create --name nova --description "OpenStack Compute" compute
fi

openstack endpoint list | grep compute
if [ $? != 0 ];then
    openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s
fi

# neutron resource
openstack user create --domain default --password neutron neutron
openstack role add --project service --user neutron admin
openstack service list | grep neutron
if [ $? != 0 ];then
    openstack service create --name neutron --description "OpenStack Networking" network
fi
openstack endpoint list | grep network
if [ $? != 0 ];then
    openstack endpoint create --region RegionOne network public http://controller:9696
    openstack endpoint create --region RegionOne network internal http://controller:9696
    openstack endpoint create --region RegionOne network admin http://controller:9696
fi


# cinder resource
openstack user create --domain default --password cinder cinder
openstack role add --project service --user cinder admin
openstack service list | grep cinder
if [ $? != 0 ];then
    openstack service create --name cinder  --description "OpenStack Block Storage" volume
fi
openstack service list | grep cinderv2
if [ $? != 0 ];then
    openstack service create --name cinderv2  --description "OpenStack Block Storage" volumev2
fi

#创建cinder服务的API endpoints
openstack endpoint list | grep volume
if [ $? != 0 ];then
    openstack endpoint create --region RegionOne   volume public http://controller:8776/v1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne   volume internal http://controller:8776/v1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne   volume admin http://controller:8776/v1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne   volumev2 public http://controller:8776/v2/%\(tenant_id\)s
    openstack endpoint create --region RegionOne   volumev2 internal http://controller:8776/v2/%\(tenant_id\)s
    openstack endpoint create --region RegionOne   volumev2 admin http://controller:8776/v2/%\(tenant_id\)s
fi



# 同步数据库
su -s /bin/sh -c "glance-manage db_sync" glance
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
su -s /bin/sh -c "cinder-manage db sync" cinder

source /root/openstack-mitaka/controller_ip

# 配置haproxy
# glance
grep "glance_api_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen glance_api_cluster
    bind $controller:9292
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:9292 check inter 2000 rise 2 fall 5
    server controller02 $controller02:9292 check inter 2000 rise 2 fall 5
    server controller03 $controller03:9292 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

grep "glance_registry_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen glance_registry_cluster
    bind $controller:9191
    balance  source
    option  tcpka
    option  tcplog
    server controller01 $controller01:9191 check inter 2000 rise 2 fall 5
    server controller02 $controller02:9191 check inter 2000 rise 2 fall 5
    server controller03 $controller03:9191 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi


grep "nova_compute_api_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen nova_compute_api_cluster
    bind $controller:8774
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:8774 check inter 2000 rise 2 fall 5
    server controller02 $controller02:8774 check inter 2000 rise 2 fall 5
    server controller03 $controller03:8774 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

grep "nova_metadata_api_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen nova_metadata_api_cluster
    bind $controller:8775
    balance  source
    option  tcpka
    option  tcplog
    server controller01 $controller01:8775 check inter 2000 rise 2 fall 5
    server controller02 $controller02:8775 check inter 2000 rise 2 fall 5
    server controller03 $controller03:8775 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

grep "nova_vncproxy_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen nova_vncproxy_cluster
    bind $controller:6080
    balance  source
    option  tcpka
    option  tcplog
    server controller01 $controller01:6080 check inter 2000 rise 2 fall 5
    server controller02 $controller02:6080 check inter 2000 rise 2 fall 5
    server controller03 $controller03:6080 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

grep "neutron_api_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen neutron_api_cluster
    bind $controller:9696
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:9696 check inter 2000 rise 2 fall 5
    server controller02 $controller02:9696 check inter 2000 rise 2 fall 5
    server controller03 $controller03:9696 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

grep "dashboard_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen dashboard_cluster
    bind $controller:80
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:80 check inter 2000 rise 2 fall 5
    server controller02 $controller02:80 check inter 2000 rise 2 fall 5
    server controller03 $controller03:80 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi


grep "cinder_api_cluster" /etc/haproxy/haproxy.cfg
if [ $? != 0 ];then
echo "
listen cinder_api_cluster
    bind $controller:8776
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
    server controller01 $controller01:8776 check inter 2000 rise 2 fall 5
    server controller02 $controller02:8776 check inter 2000 rise 2 fall 5
    server controller03 $controller03:8776 check inter 2000 rise 2 fall 5
" >> /etc/haproxy/haproxy.cfg
fi

# 拷贝至其他控制节点
/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller02 /etc/haproxy/haproxy.cfg
/root/openstack-mitaka/expect_scp.sh /etc/haproxy/haproxy.cfg controller03 /etc/haproxy/haproxy.cfg


# pcs配置资源
# glance cluster
pcs resource create openstack-glance-registry systemd:openstack-glance-registry --clone interleave=true
pcs resource create openstack-glance-api systemd:openstack-glance-api --clone interleave=true
pcs constraint order start openstack-keystone-clone then openstack-glance-registry-clone
pcs constraint order start openstack-glance-registry-clone then openstack-glance-api-clone
pcs constraint colocation add openstack-glance-api-clone with openstack-glance-registry-clone
# nova cluster
pcs resource create openstack-nova-consoleauth systemd:openstack-nova-consoleauth --clone interleave=true
pcs resource create openstack-nova-novncproxy systemd:openstack-nova-novncproxy --clone interleave=true
pcs resource create openstack-nova-api systemd:openstack-nova-api --clone interleave=true
pcs resource create openstack-nova-scheduler systemd:openstack-nova-scheduler --clone interleave=true
pcs resource create openstack-nova-conductor systemd:openstack-nova-conductor --clone interleave=true
pcs constraint order start openstack-keystone-clone then openstack-nova-consoleauth-clone
pcs constraint order start openstack-nova-consoleauth-clone then openstack-nova-novncproxy-clone
pcs constraint colocation add openstack-nova-novncproxy-clone with openstack-nova-consoleauth-clone
pcs constraint order start openstack-nova-novncproxy-clone then openstack-nova-api-clone
pcs constraint colocation add openstack-nova-api-clone with openstack-nova-novncproxy-clone
pcs constraint order start openstack-nova-api-clone then openstack-nova-scheduler-clone
pcs constraint colocation add openstack-nova-scheduler-clone with openstack-nova-api-clone
pcs constraint order start openstack-nova-scheduler-clone then openstack-nova-conductor-clone
pcs constraint colocation add openstack-nova-conductor-clone with openstack-nova-scheduler-clone

# neutron cluster
pcs resource create neutron-server systemd:neutron-server op start timeout=90 --clone interleave=true
pcs constraint order start openstack-keystone-clone then neutron-server-clone
pcs resource create neutron-scale ocf:neutron:NeutronScale --clone globally-unique=true clone-max=3 interleave=true
pcs constraint order start neutron-server-clone then neutron-scale-clone
pcs resource create neutron-ovs-cleanup ocf:neutron:OVSCleanup --clone interleave=true
pcs resource create neutron-netns-cleanup ocf:neutron:NetnsCleanup --clone interleave=true
pcs resource create neutron-openvswitch-agent systemd:neutron-openvswitch-agent --clone interleave=true
pcs resource create neutron-dhcp-agent systemd:neutron-dhcp-agent --clone interleave=true
pcs resource create neutron-metadata-agent systemd:neutron-metadata-agent  --clone interleave=true
pcs constraint order start neutron-scale-clone then neutron-ovs-cleanup-clone
pcs constraint colocation add neutron-ovs-cleanup-clone with neutron-scale-clone
pcs constraint order start neutron-ovs-cleanup-clone then neutron-netns-cleanup-clone
pcs constraint colocation add neutron-netns-cleanup-clone with neutron-ovs-cleanup-clone
pcs constraint order start neutron-netns-cleanup-clone then neutron-openvswitch-agent-clone
pcs constraint colocation add neutron-openvswitch-agent-clone with neutron-netns-cleanup-clone
pcs constraint order start neutron-openvswitch-agent-clone then neutron-dhcp-agent-clone
pcs constraint colocation add neutron-dhcp-agent-clone with neutron-openvswitch-agent-clone
pcs constraint order start neutron-dhcp-agent-clone then neutron-metadata-agent-clone
pcs constraint colocation add neutron-metadata-agent-clone with neutron-dhcp-agent-clone
# cinder cluster
pcs resource create openstack-cinder-api systemd:openstack-cinder-api --clone interleave=true
pcs resource create openstack-cinder-scheduler systemd:openstack-cinder-scheduler --clone interleave=true
pcs resource create openstack-cinder-volume systemd:openstack-cinder-volume
pcs constraint order start openstack-keystone-clone then openstack-cinder-api-clone
pcs constraint order start openstack-cinder-api-clone then openstack-cinder-scheduler-clone
pcs constraint colocation add openstack-cinder-scheduler-clone with openstack-cinder-api-clone
pcs constraint order start openstack-cinder-scheduler-clone then openstack-cinder-volume
pcs constraint colocation add openstack-cinder-volume with openstack-cinder-scheduler-clone

# heat cluster
#pcs resource create openstack-heat-api-clone systemd:openstack-heat-api --clone interleave=true
#pcs resource create openstack-heat-api-cfn-clone systemd:openstack-heat-api-cfn --clone interleave=true
#pcs resource create openstack-heat-engine-clone systemd:openstack-heat-engine
#pcs constraint order start openstack-keystone-clone then openstack-heat-api-clone
#pcs constraint order start openstack-heat-api-clone then openstack-heat-api-cfn-clone --force
#pcs constraint colocation add openstack-heat-api-cfn-clone with openstack-heat-api-clone --force
#pcs constraint order start openstack-heat-api-cfn-clone then openstack-heat-engine-clone --force
#pcs constraint colocation add openstack-heat-engine-clone with openstack-heat-api-cfn-clone --force

# 重启haproxy资源
pcs resource restart haproxy-clone
pcs resource restart openstack-keystone-clone
pcs resource cleanup neutron-server