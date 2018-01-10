# coding:utf-8

"""核心代码"""
import os
import sys
import threading
import datetime
import paramiko
import logger
import multiprocessing

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)
from utils import parseconfig
from conf import  settings
LOG_PATH = os.path.join(BASE_DIR,'log')
CONF_PATH = os.path.join(BASE_DIR,'conf')
SHELL_PATH = os.path.join(BASE_DIR,'Mitaka_L2')



class paramiko_operate(object):
    """
    远程SSH执行，如果想要远程执行SHELL脚本，必须事先把本地脚本拷贝到远端，才好批量执行SHELL脚本
    """
    def __init__(self,host,port,username,password):
        self.host= host
        self.port = port
        self.username = username
        self.password= password

    def ssh_exec_command(self,shell_commands):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)
        ssh.connect(hostname=self.host,port=self.port,username=self.username,password=self.password)
        for shell_command in shell_commands:
            stdin,stdout,stderr = ssh.exec_command(shell_command)
            # 执行SHELL脚本退出状态 0表示正常执行并退出，非0表示不正常退出
            # channel = stdout.channel
            # status = channel.recv_exit_status()
            result = stdout.read()
            error = stderr.read()
            # print(shell_command,type(shell_command))
            # print(result,status)
            print(result,error)
            logger.loggs('result:%s===========error:%s' %(result,error),'/var/log/mitaka.log')
        ssh.close()

    def sftp(self,scp_commands):
        trans = paramiko.Transport(self.host,self.port)
        trans.connect(username=self.username,password=self.password)
        sftp = paramiko.SFTPClient.from_transport(trans)
        sftp.put(scp_commands['localpath'],scp_commands['remotepath'])
        trans.close()

    def upload(self,local_dir, remote_dir):
        self.local_dir = local_dir
        self.remote_dir = remote_dir
        try:
            t = paramiko.Transport(self.host, self.port)
            t.connect(username=self.username, password=self.password)
            sftp = paramiko.SFTPClient.from_transport(t)
            # print 'upload file start %s ' % datetime.datetime.now()
            for root, dirs, files in os.walk(self.local_dir):
                for name in dirs:
                    local_path = os.path.join(root, name)
                    remote_path = os.path.join(self.remote_dir, name)
                    try:
                        sftp.mkdir(remote_path)
                        print "mkdir path %s" % remote_path
                    except Exception, e:
                        print e

                for filespath in files:
                    local_file = os.path.join(root, filespath)  # 本地文件绝对路径
                    remote_file = os.path.join(self.remote_dir, filespath)
                    try:
                        sftp.put(local_file, remote_file)
                    except Exception, e:
                        sftp.mkdir(os.path.split(remote_file)[0])
                        sftp.put(local_file, remote_file)
                    print "upload %s to remote %s" % (local_file,remote_file)

            # print 'upload file success %s ' % datetime.datetime.now()
            t.close()
        except Exception, e:
            print e

    def start_run(self,local_dir,remote_dir,shell_commands):
        self.local_dir = local_dir
        self.remote_dir = remote_dir
        self.shell_commands = shell_commands
        # self.sftp(self.scp_commands)
        self.upload(self.local_dir,self.remote_dir)
        self.ssh_exec_command(self.shell_commands)
"""
在CPU密集型任务下，多进程更快，或者说效果更好；而IO密集型，多线程能有效提高效率:
一些进程绝大多数时间在计算上，称为计算密集型（CPU密集型）computer-bound。
有一些进程则在input 和output上花费了大多时间，称为I/O密集型，
I/O-bound。比如搜索引擎蜘蛛大多时间是在等待相应这种就属于I/O密集型。
"""
# class MulThreadController(object):
#     """多线程执行Controller命令"""
#     def __init__(self,shell_commands):
#         self.shell_commands = shell_commands
#         self.controller_dict = settings.host_data['controller_node']
#
#
#     def MulParamikoController(self):
#         controller_thread_list = []
#         for hostname,data in self.controller_dict.items():
#             print hostname
#             if hostname == 'controller':
#                 pass
#             else:
#                 host, port, username, password = \
#                 data['IP'],data['port'],data['username'],data['password']
#                 instance = paramiko_operate(host, port, username, password)
#                 t = threading.Thread(target=instance.ssh_exec_command,args=(self.shell_commands,))
#                 t.start()
#                 controller_thread_list.append(t)
#                 for t in controller_thread_list:
#                     t.join()   # 主线程等待子线程执行完毕
class MulThreadController(object):
    """多线程执行Controller命令"""
    def __init__(self,shell_commands):
        self.shell_commands = shell_commands
        self.controller_dict = settings.host_data['controller_node']
        self.process_list = []
    def MulParamikoController(self):
        for hostname,data in self.controller_dict.items():
            print hostname
            if hostname == 'controller':
                pass
            else:
                host, port, username, password = \
                data['IP'],data['port'],data['username'],data['password']
                instance = paramiko_operate(host, port, username, password)
                # for i in xrange(3):
                #     p = multiprocessing.Process(target=instance.ssh_exec_command, args=(self.shell_commands,))
                #     self.process_list.append(p)
                #     p.start()
                p = multiprocessing.Process(target=instance.ssh_exec_command, args=(self.shell_commands,))
                p.start()
                p.join()
                # for i in self.process_list:
                #     p.join()

                # instance.ssh_exec_command(self.shell_commands)


class MulThreadCompute(object):
    """多线程执行Controller命令"""
    def __init__(self,shell_commands):
        self.shell_commands = shell_commands
        self.compute_dict = settings.host_data['compute_node']
        # self.process_list = []
    def MulParamikoCompute(self):
        result = []
        for hostname,data in self.compute_dict.items():
            print hostname
            if hostname == 'controller':
                pass
            else:
                host, port, username, password = \
                data['IP'],data['port'],data['username'],data['password']
                instance = paramiko_operate(host, port, username, password)
                # for i in xrange(8):
                p = multiprocessing.Process(target=instance.ssh_exec_command, args=(self.shell_commands,))
                # self.process_list.append(p)
                p.start()
                p.join()
                # for i in self.process_list:
                #     p.join()

# class MulThreadCompute(object):
#     """多线程执行计算节点命令"""
#     def __init__(self,shell_commands):
#         self.shell_commands = shell_commands
#         self.compute_dict = settings.host_data['compute_node']
#
#
#     def MulParamikoCompute(self):
#         compute_thread_list = []
#         for hostname,data in self.compute_dict.items():
#             if hostname == 'controller':
#                 pass
#             else:
#                 host, port, username, password = \
#                 data['IP'],data['port'],data['username'],data['password']
#                 instance = paramiko_operate(host, port, username, password)
#                 t = threading.Thread(target=instance.ssh_exec_command,args=(self.shell_commands,))
#                 t.start()
#                 compute_thread_list.append(t)
#                 for t in compute_thread_list:
#                     t.join()   # 主线程等待子线程执行完毕


# class ComputeUpload(object):
#     """上传SHELL脚本到计算节点"""
#     def __init__(self,local_dir,remote_dir):
#         self.local_dir = local_dir
#         self.remote_dir = remote_dir
#         self.compute_dict = settings.host_data['compute_node']
#
#     def upload(self):
#         """上传SHELL脚本"""
#         compute_thread_list = []
#         for hostname, data in self.compute_dict.items():
#             print hostname
#             if hostname == 'controller':
#                 pass
#             else:
#                 host, port, username, password = \
#                     data['IP'], data['port'], data['username'], data['password']
#                 instance = paramiko_operate(host, port, username, password)
#                 t = threading.Thread(target=instance.upload,
#                                      args=(self.local_dir, self.remote_dir))
#                 t.start()
#                 compute_thread_list.append(t)
#                 for t in compute_thread_list:
#                     t.join()  # 主线程等待子线程执行完毕
class ComputeUpload(object):
    """上传SHELL脚本到计算节点"""
    def __init__(self,local_dir,remote_dir):
        self.local_dir = local_dir
        self.remote_dir = remote_dir
        self.compute_dict = settings.host_data['compute_node']
        self.process_list = []
    def upload(self):
        """上传SHELL脚本"""
        for hostname, data in self.compute_dict.items():
            print hostname
            if hostname == 'controller':
                pass
            else:
                host, port, username, password = \
                    data['IP'], data['port'], data['username'], data['password']
                instance = paramiko_operate(host, port, username, password)
                # for i in xrange(8):
                p = multiprocessing.Process(target=instance.upload, args=(self.local_dir, self.remote_dir,))
                # self.process_list.append(p)
                p.start()
                # for i in self.process_list:
                #     p.join()




# class ControllerUpload(object):
#     """上传SHELL脚本到控制节点"""
#     def __init__(self,local_dir,remote_dir):
#         self.local_dir = local_dir
#         self.remote_dir = remote_dir
#         self.controller_dict = settings.host_data['controller_node']
#
#
#     def upload(self):
#         """上传SHELL脚本"""
#         controller_thread_list = []
#         for hostname, data in self.controller_dict.items():
#             print hostname
#             if hostname == 'controller':
#                 pass
#             else:
#                 host, port, username, password = \
#                     data['IP'], data['port'], data['username'], data['password']
#                 instance = paramiko_operate(host, port, username, password)
#                 t = threading.Thread(target=instance.upload,
#                                      args=(self.local_dir, self.remote_dir))
#                 t.start()
#                 controller_thread_list.append(t)
#                 for t in controller_thread_list:
#                     t.join()  # 主线程等待子线程执行完毕
class ControllerUpload(object):
    """上传SHELL脚本到控制节点"""
    def __init__(self,local_dir,remote_dir):
        self.local_dir = local_dir
        self.remote_dir = remote_dir
        self.controller_dict = settings.host_data['controller_node']
        self.process_list = []


    def upload(self):
        """上传SHELL脚本"""
        for hostname, data in self.controller_dict.items():
            print hostname
            if hostname == 'controller':
                pass
            else:
                host, port, username, password = \
                    data['IP'], data['port'], data['username'], data['password']
                instance = paramiko_operate(host, port, username, password)
                # for i in xrange(8):
                p = multiprocessing.Process(target=instance.upload, args=(self.local_dir, self.remote_dir,))
                # self.process_list.append(p)
                p.start()
                # for i in self.process_list:
                #     p.join()
                # instance.upload(self.local_dir,self.remote_dir)

def upload(local_dir,remote_dir):
    ControllerUpload(local_dir,remote_dir).upload()
    ComputeUpload(local_dir,remote_dir).upload()

def run_upload():
    """上传脚本到指定目录"""
    parseconfig.parse_run()
    parseconfig.parse_run2()
    local_dirs = SHELL_PATH
    remote_dirs = '/root/openstack-mitaka/'
    upload(local_dirs,remote_dirs)

class MultiRun(object):
    """在所有controller，compute批量执行脚本"""

    def __init__(self,cmd_list):
        self.cmd_list = cmd_list
        self.shell_commands = self.cmd_list

    def run(self):
        controller = MulThreadController(shell_commands=self.shell_commands)
        controller.MulParamikoController()
        compute = MulThreadCompute(shell_commands=self.shell_commands)
        compute.MulParamikoCompute()

class ComRun(object):
    """在所有compute批量执行脚本"""

    def __init__(self,cmd_list):
        self.cmd_list = cmd_list
        self.shell_commands = self.cmd_list

    def run(self):
        compute = MulThreadCompute(shell_commands=self.shell_commands)
        compute.MulParamikoCompute()

class ConRun(object):
    """在所有controller批量执行脚本"""

    def __init__(self,cmd_list):
        self.cmd_list = cmd_list
        self.shell_commands = self.cmd_list

    def run(self):
        controller = MulThreadController(shell_commands=self.shell_commands)
        controller.MulParamikoController()

class Con23Run(object):
    """在所有controller2，和3上批量执行脚本"""

    def __init__(self, cmd_list):
        self.cmd_list = cmd_list

    def run(self):
        controller02_IP = settings.host_data['controller_node']['controller02']['IP']
        controller02_user = settings.host_data['controller_node']['controller02']['username']
        controller02_password = settings.host_data['controller_node']['controller02']['password']
        controller02_port = settings.host_data['controller_node']['controller02']['port']
        controller02 = paramiko_operate(host=controller02_IP, port=controller02_port, username=controller02_user,
                                        password=controller02_password)
        # local_dirs = SHELL_PATH
        # remote_dirs = '/root/openstack-mitaka/'
        self.shell_commands = self.cmd_list
        controller02.ssh_exec_command(shell_commands=self.shell_commands)

        controller03_IP = settings.host_data['controller_node']['controller03']['IP']
        controller03_user = settings.host_data['controller_node']['controller03']['username']
        controller03_password = settings.host_data['controller_node']['controller03']['password']
        controller03_port = settings.host_data['controller_node']['controller03']['port']
        controller03 = paramiko_operate(host=controller03_IP, port=controller03_port, username=controller03_user,
                                        password=controller03_password)
        # local_dirs = SHELL_PATH
        # remote_dirs = '/root/openstack-mitaka/'
        # self.shell_commands = self.cmd_list
        controller03.ssh_exec_command(shell_commands=self.shell_commands)




def show_menu():
    """通过选择分组显示主机名与IP"""
    print('*'*80)
    for index, key in enumerate(settings.host_data):
        print(index + 1, key, len(settings.host_data[key]))
    print('第一列是序号，第二列是主机名,第三列是主机数')
    print('*'*80)
    print('请选择安装模式(输入1或者2)')
    print('1) OpenStack-Mitaka L2层')
    print('2) OpenStack-Mitaka DVR模式')
    print('*' * 80)

    choice = input("请输入你要选择的模式编号(1/2):")
    if choice == 1:
        pass
    else:
        pass


class SimpleRun(object):
    """在controller01上执行脚本"""

    def __init__(self,cmd_list):
        self.cmd_list = cmd_list
    def run(self):
        controller01_IP = settings.host_data['controller_node']['controller01']['IP']
        controller01_user = settings.host_data['controller_node']['controller01']['username']
        controller01_password = settings.host_data['controller_node']['controller01']['password']
        controller01_port = settings.host_data['controller_node']['controller01']['port']
        controller01 = paramiko_operate(host=controller01_IP,port=controller01_port,username=controller01_user,password=controller01_password)
        # local_dirs = SHELL_PATH
        # remote_dirs = '/root/openstack-mitaka/'
        self.shell_commands = self.cmd_list
        controller01.ssh_exec_command(shell_commands=self.shell_commands)


def run_init_base():
    """执行init_base脚本"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka',
                '/root/openstack-mitaka/init_base.sh']
    multirun = MultiRun(cmd_list)
    multirun.run()

def run_ntp_server():
    """执行ntp-server"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/ntp_server.sh']
    simplerun = SimpleRun(cmd_list)
    simplerun.run()

def run_ssh_trust():
    """执行init_base脚本"""
    cmd_list = [ 'chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/exec_ssh.sh']
    multirun = MultiRun(cmd_list)
    multirun.run()

# def run_ssh_trust_controller01():
#     cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/exec_ssh.sh']
#     simplerun = SimpleRun(cmd_list)
#     simplerun.run()

def run_ntp_client():
    """执行ntp-client"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/ntp_client.sh']
    multirun = MultiRun(cmd_list)
    multirun.run()

def run_updata_hostname():
    """批量修改主机名"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/update_hostname.sh']
    multirun = MultiRun(cmd_list)
    multirun.run()

def run_install_haproxy():
    """安装配置haproxy"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/install_haproxy.sh']
    conrun = ConRun(cmd_list)
    conrun.run()

def run_install_pacemaker():
    """安装pacemaker"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/install_pacemaker.sh']
    conrun = ConRun(cmd_list)
    conrun.run()

def run_install_mariadb():
    """安装配置mariadb"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/install_mariadb.sh']
    conrun = ConRun(cmd_list)
    conrun.run()

def run_new_galera():
    """执行new galera"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller01_mariadb.sh']
    simplerun = SimpleRun(cmd_list)
    simplerun.run()

def run_restart_mariadb():
    """重启mariadb集群"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller23_mariadb.sh']
    con23run = Con23Run(cmd_list)
    con23run.run()

def run_haproxy_pacemaker():
    """在控制节点1上安装配置pacemaker"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/haproxy_pacemaker.sh']
    simplerun = SimpleRun(cmd_list)
    simplerun.run()

def run_haproxy_health():
    """所有控制节点执行haproxy状态检查"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/haproxy_health.sh']
    conrun = ConRun(cmd_list)
    conrun.run()

def run_install_rabbitmq():
    """所有控制节点执行haproxy状态检查"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/install_rabbitmq.sh']
    conrun = ConRun(cmd_list)
    conrun.run()



def run_controller01_rabbitmq():
    """在控制节点1节点上安装配置rabbitmq"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller01_config_rabbitmq.sh']
    simplerun = SimpleRun(cmd_list)
    simplerun.run()

def run_controller23_rabbitmq():
    """在控制节点23节点上安装配置rabbitmq"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller23_config_rabbitmq.sh']
    con23run = Con23Run(cmd_list)
    con23run.run()

def run_controller01_rabbitmq_cluster():
    """在控制节点1节点上安装配置rabbitmq"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller01_rabbitmq_cluster.sh']
    simplerun = SimpleRun(cmd_list)
    simplerun.run()

def run_install_memcached():
    """所有控制节点执行haproxy状态检查"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/install_config_memcached.sh']
    conrun = ConRun(cmd_list)
    conrun.run()

def run_install_keystone():
    """在控制节点1节点上安装配置rabbitmq"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller_install_keystone.sh']
    conrun = ConRun(cmd_list)
    conrun.run()
def run_controller01_keystone():
    """在控制节点1节点上安装配置rabbitmq"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller_config_keystone.sh']
    simplerun = SimpleRun(cmd_list)
    simplerun.run()

def run_install_openstack():
    """在控制节点1节点上安装配置rabbitmq"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller_install_openstack.sh']
    conrun = ConRun(cmd_list)
    conrun.run()

def run_controller01_openstack():
    """在控制节点1节点上安装配置rabbitmq"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/controller_config_openstack.sh']
    simplerun = SimpleRun(cmd_list)
    simplerun.run()

def run_compute_openstack():
    """安装配置计算节点"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/install_compute.sh']
    comrun = ComRun(cmd_list)
    comrun.run()

def run_compute_nova():
    """安装配置计算节点"""
    cmd_list = ['chmod -R 777 /root/openstack-mitaka','/root/openstack-mitaka/exec_ssh_nova.sh']
    comrun = ComRun(cmd_list)
    comrun.run()



def init_base():
    run_upload()
    run_init_base()
    run_ssh_trust()
    run_ntp_server()
    run_ntp_client()
    run_updata_hostname()

def install_mariadb():
    run_install_haproxy()
    run_install_pacemaker()
    run_install_mariadb()
    run_new_galera()
    run_restart_mariadb()
    run_haproxy_pacemaker()
    run_haproxy_health()

def install_rabbitmq():
    run_install_rabbitmq()
    run_controller01_rabbitmq()
    run_controller23_rabbitmq()
    run_controller01_rabbitmq_cluster()

def install_memcached():
    run_install_memcached()

def install_keystone():
    run_install_keystone()
    run_controller01_keystone()

def install_openstack():
    run_install_openstack()
    run_controller01_openstack()

def install_compute():
    run_compute_openstack()
    run_compute_nova()


if __name__ == '__main__':
    init_base()
    install_mariadb()
    install_rabbitmq()
    install_memcached()
    install_keystone()
    install_openstack()
    install_compute()
#


