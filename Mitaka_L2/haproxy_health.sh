#!/bin/bash

yum install xinetd -y



mysql -u root -proot1234 -e "GRANT PROCESS ON *.* TO 'clustercheck'@'localhost' IDENTIFIED BY 'root1234';"
mysql -u root -proot1234 -e "FLUSH PRIVILEGES;"

echo "MYSQL_USERNAME='clustercheck'
MYSQL_PASSWORD='root1234'
MYSQL_HOST='localhost'
MYSQL_PORT='3306'" > /etc/sysconfig/clustercheck

echo "
service mysqlchk
{
   port = 9200
   disable = no
   socket_type = stream
   protocol = tcp
   wait = no
   user = root
   group = root
   groups = yes
   server = /usr/bin/clustercheck
   type = UNLISTED
   per_source = UNLIMITED
   log_on_success =
   log_on_failure = HOST
   flags = REUSE
}

" > /etc/xinetd.d/galera-monitor

grep "mysqlchk" /etc/services
if [ $? != 0 ];then

    echo "mysqlchk	9200/tcp	# MySQL check" >> /etc/services

fi


systemctl daemon-reload
systemctl enable xinetd
systemctl start xinetd
systemctl restart xinetd



