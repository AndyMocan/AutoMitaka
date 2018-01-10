#!/bin/bash

source_file=$1
dest_file=$3
dest_host=$2
TMP_SCRIPT=/tmp/tmp.sh
echo  "#!/usr/bin/expect">$TMP_SCRIPT
echo  "spawn scp $source_file $dest_host:$dest_file">>$TMP_SCRIPT
echo  "expect *yes/no*">>$TMP_SCRIPT
echo  "send yes\r">>$TMP_SCRIPT
echo  "interact">>$TMP_SCRIPT

chmod +x $TMP_SCRIPT
/usr/bin/expect $TMP_SCRIPT
rm -f $TMP_SCRIPT
