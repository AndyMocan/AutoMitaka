#!/bin/bash

# 安装包
yum install openstack-glance python-glance python-glanceclient -y
yum install openstack-nova-api openstack-nova-cert \
  openstack-nova-conductor openstack-nova-console \
  openstack-nova-novncproxy openstack-nova-scheduler \
  python-novaclient -y

yum install openstack-neutron openstack-neutron-ml2 ebtables openstack-neutron-openvswitch.noarch -y

yum install openstack-cinder python-cinderclient -y
yum install openstack-cinder targetcli python-keystone -y

#rpm -qa | grep openstack-dashboard
#if [ $? -eq 0 ];then
#    rm -f /etc/openstack-dashboard/local_settings
#    yum reinstall -y openstack-dashboard
#else
#    yum install -y openstack-dashboard
#fi
yum install -y openstack-dashboard

# glance配置
openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://root:root1234@controller/glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password glance
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-api.conf glance_store stores file,http
openstack-config --set /etc/glance/glance-api.conf glance_store default_store file
openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_host controller


data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
        openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host $host_ip
    fi
done

# [所有控制节点]配置/etc/glance/glance-registry.conf文件
openstack-config --set /etc/glance/glance-registry.conf database connection mysql+pymysql://root:root1234@controller/glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken password glance
openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_host controller
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/glance/glance-registry.conf DEFAULT registry_host controller
for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
        openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_host $host_ip
    fi
done


# nova 配置
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://root:root1234@controller/nova_api
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://root:root1234@controller/nova
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host controller
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password root1234
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password nova
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf glance api_servers http://controller:9292
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
openstack-config --set /etc/nova/nova.conf cinder os_region_name RegionOne

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then

        openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $host_ip
        openstack-config --set /etc/nova/nova.conf vnc vncserver_listen $host_ip
        openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $host_ip
        openstack-config --set /etc/nova/nova.conf vnc novncproxy_host $host_ip
        openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen $host_ip
        openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen $host_ip
    fi
done
# [所有控制节点]配置nova和neutron集成，/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password neutron
openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret root1234

# neutron配置文件
for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
        openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $host_ip
    fi
done

openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://root:root1234@controller/neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host controller
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password root1234
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password nova
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 3
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

# [所有控制节点]配置ML2 plugin，/etc/neutron/plugins/ml2/ml2_conf.ini
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges external:1:4090
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver iptables_hybrid

# [所有控制节点]配置Open vSwitch agent，/etc/neutron/plugins/ml2/openvswitch_agent.ini，注意，此处填写业务网卡

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent prevent_arp_spoofing False
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings external:br-ex

# [所有控制节点]配置DHCP agent，/etc/neutron/dhcp_agent.ini
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True

# [所有控制节点]配置metadata agent，/etc/neutron/metadata_agent.ini
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret root1234
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini





# 配置ovs网桥
# 配置资源之前得先创建br-ex网桥，并且把第二张网卡加入到br-ex上，为了L3层考虑，还有预留一张网卡做隧道备用
systemctl enable openvswitch.service
systemctl start openvswitch.service
for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    buscard=`echo $host | awk -F ',' '{print $4}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
echo "TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
NAME=$buscard
DEVICE=$buscard
ONBOOT=yes">/etc/sysconfig/network-scripts/ifcfg-$buscard

ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $buscard
ifdown $buscard
ifup $buscard
    fi
done










# cinder 配置文件
openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://root:root1234@controller/cinder
openstack-config --set /etc/cinder/cinder.conf database max_retries -1
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password cinder

openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host controller
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password root1234
openstack-config --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://controller:9292

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen  $host_ip
    openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip $host_ip
done

#openstack-config --set /etc/cinder/cinder.conf lvm volume_driver  cinder.volume.drivers.lvm.LVMVolumeDriver
#openstack-config --set /etc/cinder/cinder.conf lvm volume_group   cinder-volumes
#openstack-config --set /etc/cinder/cinder.conf lvm iscsi_protocol iscsi
#openstack-config --set /etc/cinder/cinder.conf lvm iscsi_helper   lioadm
#openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends  lvm

# 安装配置dashboard

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    sed -i \
    -e "s#OPENSTACK_HOST =.*#OPENSTACK_HOST = '$host_ip'#g" /etc/openstack-dashboard/local_settings
done
sed -i \
    -e "s#ALLOWED_HOSTS.*#ALLOWED_HOSTS = ['*',]#g" \
    -e "s#^CACHES#SESSION_ENGINE = 'django.contrib.sessions.backends.cache'\nCACHES#g#" \
    -e "s#locmem.LocMemCache'#memcached.MemcachedCache',\n        'LOCATION' : 'controller:11211'#g" \
    -e 's#^OPENSTACK_KEYSTONE_URL =.*#OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST#g' \
    -e "s/^#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT.*/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g" \
    -e 's/^#OPENSTACK_API_VERSIONS.*/OPENSTACK_API_VERSIONS = {\n    "identity": 3,\n    "image": 2,\n    "volume": 2,\n}\n#OPENSTACK_API_VERSIONS = {/g' \
    -e "s/^#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN.*/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'/g" \
    -e 's#^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*#OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"#g' \
    -e "s#^LOCAL_PATH.*#LOCAL_PATH = '/var/lib/openstack-dashboard'#g" \
    -e "s#^SECRET_KEY.*#SECRET_KEY = '4050e76a15dfb7755fe3'#g" \
    -e "s#'enable_ha_router'.*#'enable_ha_router': False,#g" \
    -e "s#'enable_quotas'.*#'enable_quotas': False,#g" \
    -e "s#'enable_router'.*#'enable_router': False,#g" \
    -e "s#'enable_ipv6'.*#'enable_ipv6': False,#g" \
    -e "s#'enable_lb'.*#'enable_lb': False,#g" \
    -e "s#'enable_firewall'.*#'enable_firewall': False,#g" \
    -e "s#'enable_vpn'.*#'enable_vpn': False,#g" \
    -e "s#'enable_fip_topology_check'.*#'enable_fip_topology_check': False,#g" \
    -e 's#TIME_ZONE = .*#TIME_ZONE = "'"Asia/Shanghai"'"#g' \
    /etc/openstack-dashboard/local_settings


