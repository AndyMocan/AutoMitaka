#!/bin/bash

source /root/openstack-mitaka/controller_ip
echo "-----------------------start install mariadb----------------------"

# 杀掉之前残余进程
for i in `ps -ef | grep -v grep | grep mysql | awk -F ' ' '{print $2}'`;do kill -9 $i;done

# Add to mysql user and mysql group
if [ `grep "mysql" /etc/passwd | wc -l` -eq 0 ];then
echo "adding user mysql"
groupadd mysql
useradd -r -g mysql mysql
else
echo "mysql user is exist"
fi


# Remove pre-installed on OS mysql if exists
for i in `rpm -qa | grep "mysql"`
do
rpm -e --allmatches $i --nodeps
done

# check installed mariadb or not
for i in $(rpm -qa | grep mariadb | grep -v grep)
do
  echo "mariadb exist --> "$i
done


# Install mariadb
yum install -y mariadb mariadb-server-galera mariadb-galera-common galera rsync


# check the installtation was successful or not
rpm -qa |grep "mariadb"
if [ $? != 0 ];then
echo "mariadb install fail"| tee $mysql_instlog
exit 1
else
echo "mariadb isntall success"| tee $mysql_instlog
fi

# modify configuration files
# configuration 跳过认证
echo "
[mysqld]
character_set_server=utf8
skip-grant-tables
" > /etc/my.cnf.d/openstack.cnf

echo "mariadb Server install successfully!"

systemctl restart mariadb
#if [ $? = 0 ];then
#    echo "mariadb restart successfully"
#else
#    exit 1
#fi
# mysql -u root mysql
mysql -u root mysql -e "use mysql;"
if [ $? != 0 ];then
    mysql -uroot -proot1234 mysql -e "use mysql;"
fi


mysql -u root mysql -e "update mysql.user set password=password('root1234') where user='root' ;"
if [ $? != 0 ];then
    mysql -uroot -proot1234 mysql -e "update mysql.user set password=password('root1234') where user='root' ;"
    echo "exec have password"
fi
mysql -u root mysql -e "flush privileges;"
if [ $? != 0 ];then
    mysql -uroot -proot1234 mysql -e "flush privileges;"
fi
# 使用认证
sed -i '/skip-grant-tables/s/^/#/' /etc/my.cnf.d/openstack.cnf
systemctl restart mariadb


# mysql -u root mysql
# use mysql;
mysql -u root -proot1234 -e "use mysql;"
# update user set host = '%' where user ='root';
mysql -u root -proot1234 -e "grant all privileges on *.* to 'root'@'%' identified by 'root1234' with grant option;"
# select host, user from user;
mysql -u root -proot1234 -e "select host, user,password from mysql.user;"
# exit
systemctl stop mariadb

echo "The mariadb install and config complete! "


# 配置galera集群
data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
echo "

datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
bind-address = $host_ip
skip-name-resolve
default-storage-engine = innodb
max_connections = 4096
binlog_format=ROW
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=2
innodb_buffer_pool_size = 256M
innodb_flush_log_at_trx_commit=0

wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_provider_options='pc.recovery=TRUE;gcache.size=300M'
wsrep_cluster_name='openstack_cluster'
wsrep_cluster_address='gcomm://controller01,controller02,controller03'
wsrep_node_name=$hostname
wsrep_node_address=$host_ip
wsrep_sst_method=rsync
wsrep_sst_auth=root:root1234
" >> /etc/my.cnf.d/openstack.cnf
sed -i "s@0.0.0.0@$host_ip@g" /etc/my.cnf.d/galera.cnf
    fi

done

# 删除galera默认配置
#rm -f /etc/my.cnf.d/galera.cnf

sed -i '/Group=mysql/a\LimitNOFILE=10000' /usr/lib/systemd/system/mariadb.service
sed -i '/Group=mysql/a\LimitNPROC=10000' /usr/lib/systemd/system/mariadb.service

systemctl --system daemon-reload
systemctl restart mariadb.service

