#!/bin/bash
/sbin/service rabbitmq-server restart

/root/openstack-mitaka/expect_scp.sh /var/lib/rabbitmq/.erlang.cookie controller02 /var/lib/rabbitmq/.erlang.cookie
/root/openstack-mitaka/expect_scp.sh /var/lib/rabbitmq/.erlang.cookie controller03 /var/lib/rabbitmq/.erlang.cookie


