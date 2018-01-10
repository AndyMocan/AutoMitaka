#!/bin/bash

yum install -y openstack-keystone httpd mod_wsgi


# 修改配置httpd 监听地址和wsgi配置
data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
sed -i -e "s@#ServerName www.example.com:80@ServerName $host_ip:80@g"  /etc/httpd/conf/httpd.conf
sed -i -e "s@Listen 80@Listen $host_ip:80@g"  /etc/httpd/conf/httpd.conf
echo "
Listen $host_ip:5000
Listen $host_ip:35357
<VirtualHost $host_ip:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat '%{cu}t %M'
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost $host_ip:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat '%{cu}t %M'
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
" > /etc/httpd/conf.d/wsgi-keystone.conf
    fi

done


