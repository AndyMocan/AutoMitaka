import re
import os,sys,datetime
import threading

class ThreadClass(threading.Thread):
    def run(self):
        now = datetime.datetime.now()
        print "%s over at time %s" % (self.getName(),now)

file_name = '/root/openstack-mitaka/hostname_ip'
f = file(file_name,'r')
for line in f.readlines():
    ip = re.findall(r'(?<![\.\d])(?:\d{1,3}\.){3}\d{1,3}(?![\.\d])', line)[0]
    print(ip)
    host = re.findall(r'(\w+)', line)[4]
    print(host)
    cmd = "hostname %s && hostnamectl set-hostname %s" % (host, host)
    process = os.popen('ssh "%s   %s"' %(ip,cmd)).read()
    t = ThreadClass()
    t.start()
