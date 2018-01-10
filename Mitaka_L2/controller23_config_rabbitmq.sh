#!/bin/bash

chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
/sbin/service rabbitmq-server restart

rabbitmqctl stop_app

rabbitmqctl join_cluster --ram rabbit@controller01
rabbitmqctl start_app


rabbitmqctl cluster_status
rabbitmq-plugins enable rabbitmq_management
rabbitmqctl set_user_tags openstack administrator
