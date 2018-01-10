#!/bin/bash


# 关闭防火墙和selinux
systemctl disable firewalld.service
systemctl stop firewalld.service
sed -i -e "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
sed -i -e "s#SELINUXTYPE=targeted#\#SELINUXTYPE=targeted#g" /etc/selinux/config
setenforce 0
systemctl stop NetworkManager
systemctl disable NetworkManager


source /root/openstack-mitaka/controller_ip
#source /root/openstack-mitaka/compute_ip




# 修改host文件
cat >  /etc/hosts << 'EOF'
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF
cat /root/openstack-mitaka/controller_ip | awk -F '=' '{print $2,$1}' >> /etc/hosts
cat /root/openstack-mitaka/compute_ip | awk -F '=' '{print $2,$1}' >> /etc/hosts

# 这里的yum源已经写死了，必须落在controller01上
if [ ! -d "/etc/yum.repos.d/bak" ];then
    mkdir "/etc/yum.repos.d/bak"
fi

mv /etc/yum.repos.d/*repo /etc/yum.repos.d/bak
echo "[base]
name=CentOS-Base
baseurl=http://$controller01/openstack/base
enabled=1
gpgcheck=0
[mitaka]
name=mitaka
baseurl=http://$controller01/openstack/openstack-mitaka
enabled=1
gpgcheck=0
[epel]
name=epel
baseurl=http://$controller01/openstack/epel
enabled=1
gpgcheck=0" > /etc/yum.repos.d/openstack-mitaka.repo


yum clean all
yum makecache
yum install vim openstack-utils python-openstackclient openstack-selinux -y



