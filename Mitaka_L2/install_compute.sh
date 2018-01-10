#!/bin/bash


yum install openstack-nova-compute -y
yum install openstack-neutron-openvswitch -y


data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`
source /root/openstack-mitaka/controller_ip

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
        openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $host_ip
        openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $host_ip
    fi
done


openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers controller:11211
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
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
openstack-config --set /etc/nova/nova.conf vnc enabled True
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://$controller:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf glance api_servers http://controller:9292
openstack-config --set /etc/nova/nova.conf libvirt virt_type  $(count=$(egrep -c '(vmx|svm)' /proc/cpuinfo); if [ $count -eq 0 ];then   echo "qemu"; else   echo "kvm"; fi)

openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password neutron

sed -i -e "s#\#listen_tls *= *0#listen_tls = 0#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#listen_tcp *= *1#listen_tcp = 1#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#auth_tcp *= *\"sasl\"#auth_tcp = \"none\"#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#LIBVIRTD_ARGS *= *\"--listen\"#LIBVIRTD_ARGS=\"--listen\"#g" /etc/sysconfig/libvirtd


systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service




# neutron config
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts controller
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
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp




openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings external:br-ex
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent prevent_arp_spoofing False


systemctl restart openstack-nova-compute.service
systemctl enable neutron-openvswitch-agent.service
systemctl start neutron-openvswitch-agent.service

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



# nova 用户的ssh互信
sed -i \
-e 's@nova.*@nova:x:162:162:OpenStack Nova Daemons:/var/lib/nova:/bin/bash@g' /etc/passwd

echo nova | passwd --stdin nova





