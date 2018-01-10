#!/bin/bash

galera_new_cluster
if [ $? != 0 ];then
    echo "  ************************************* galera_new_cluster start successfully"
fi
#systemctl restart mariadb
#if [ $? != 0 ];then
#    exit 1
#fi
tail -10 /var/log/mariadb/mariadb.log