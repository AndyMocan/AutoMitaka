#!/bin/bash
username=$1
password=$2
hostfile=$3
data=`cat /root/openstack-mitaka/compute_ip_netcard /root/openstack-mitaka/controller_ip_netcard`

for host in $data;do
    hostname=`echo $host | awk -F ',' '{print $1}'`
    ip=`echo $host | awk -F ',' '{print $2}'`
    mancard=`echo $host | awk -F ',' '{print $3}'`
    host_ip=`ifconfig $mancard | grep 'netmask' | awk -F ' ' '{print $2}'`
    if [ "$ip" = "$host_ip" ];then
        src_host=$host_ip
    fi
done

#在本机上生成密钥对
Keygen()
{
expect << EOF

spawn ssh $username@$src_host
spawn ssh-keygen -b 1024 -t rsa
while 1 {

        expect {
                        "password:" {
                                        send "$password\n"
                        }
                        "yes/no*" {
                                        send "yes\n"
                        }
                        "Enter file in which to save the key*" {
                                        send "\n"
                        }
                        "Enter passphrase*" {
                                        send "\n"
                        }
                        "Enter same passphrase again:" {
                                        send "\n"
                                        }

                        "Overwrite (y/n)" {
                                        send "y\n"
                        }
                        eof {
                                   exit
                        }

        }
}
EOF
}


# 将本地公钥拷贝到远程主机
#Put_pub()
#{
#src_pub="$(cat /tmp/id_rsa.pub)"
#expect << EOF
#spawn ssh $dst_username@$dst_host "chmod 700 ~/.ssh;echo $src_pub >> ~/.ssh/authorized_keys;chmod 600 ~/.ssh/authorized_ke
#ys"
#expect {
#            "password:" {
#                        send "$dst_passwd\n";exp_continue
#             }
#            "yes/no*" {
#                        send "yes\n";exp_continue
#             }
#            eof {
#                        exit
#             }
#}
#EOF
#}
auto_ssh_copy_id() {
    expect -c "set timeout -1;
        spawn ssh-copy-id $username@$1;
        expect {
            *(yes/no)* {send -- yes\r;exp_continue;}
            *assword:* {send -- $password\r;exp_continue;}
            eof        {exit 0;}
        }";
}

ssh_copy_id_to_all() {
    for host in $(cat $hostfile)
    do
        auto_ssh_copy_id $host
    done
}


Keygen
ssh_copy_id_to_all
