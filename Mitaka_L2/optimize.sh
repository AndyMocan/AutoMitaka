#!/bin/bash


echo "
*       soft    nproc     65536
*       hard    nproc    65536
*       soft    nofile    65536
*       hard    nofile   65536
*              soft        stack       65536
*              hard        stack       65536
root       soft    nproc     unlimited
root       hard    nproc     unlimited
" >  /etc/security/limits.d/20-nproc.conf
ulimit -n 10240

