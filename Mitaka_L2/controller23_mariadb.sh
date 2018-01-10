#!/bin/bash
systemctl start mariadb
if [ $? != 0 ];then
    echo "  ************************************* systemctl start mariadb start successfully"
fi
systemctl restart mariadb
if [ $? != 0 ];then
        echo " ************************************* systemctl start mariadb restart successfully"

fi
