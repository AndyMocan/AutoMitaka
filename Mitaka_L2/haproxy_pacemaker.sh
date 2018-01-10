#!/bin/bash
source /root/openstack-mitaka/controller_ip

pcs cluster auth controller01 controller02 controller03 -u hacluster -p hacluster --force
pcs cluster setup --force --name openstack-cluster controller01 controller02 controller03
pcs cluster start --all
pcs property set pe-warn-series-max=1000 pe-input-series-max=1000 pe-error-series-max=1000 cluster-recheck-interval=5min
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
pcs resource create vip ocf:heartbeat:IPaddr2 params ip=$controller cidr_netmask="24" op monitor interval="30s"
pcs resource op defaults timeout=90s
corosync-cmapctl runtime.totem.pg.mrp.srp.members



# [controller01]在pacemaker集群增加haproxy资源
pcs resource create haproxy systemd:haproxy --clone
# Optional表示只在同时停止和/或启动两个资源时才会产生影响。对第一个指定资源进行的任何更改都不会对第二个指定的资源产生影响，定义在前面的资源先确保运行。
pcs constraint order start vip then haproxy-clone kind=Optional
# vip的资源决定了haproxy-clone资源的位置约束
pcs constraint colocation add haproxy-clone with vip
ping -c 3 $controller