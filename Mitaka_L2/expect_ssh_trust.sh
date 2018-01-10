#!/bin/bash
auto_smart_ssh () {
    expect -c "set timeout -1;
                spawn ssh -o StrictHostKeyChecking=no $2 ${@:3};
                expect {
                    *assword:* {send -- $1\r;
                                 expect {
                                    *denied* {exit 2;}
                                    eof
                                 }
                    }
                    eof         {exit 1;}
                }
                "
    return $?
}

auto_smart_ssh passwd user@host ls /var
echo -e "\n---Exit Status: $?"




################
password=$2

if ! which expect >/dev/null 2>&1; then yum install -y -q expect;fi

expect << EOF
set timeout 30
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$1
expect {
    "(yes/no)" {send "yes\r"; exp_continue}
    "password:" {send "$password\r"}
}
expect eof
EOF