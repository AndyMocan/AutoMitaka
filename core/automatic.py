# coding:utf-8
import paramiko
from  optparse import OptionParser
import configparser
import os, sys
from multiprocessing import Pool
import logger  # 插入日志模块

'''默认配置文件路径和日志文件路径'''
CONF_PATH = os.path.abspath(os.path.join(os.path.dirname('.'), 'conf'))
LOG_PATH = os.path.abspath(os.path.join(os.path.dirname('.'), 'log'))
'''解析配置文件，设置默认sections和options,pkey_file指定密钥文件名，fork表示默认开启5个进程'''


def ConfigParser(group):
    config = configparser.ConfigParser()
    config['DEFAULT'] = {'user': 'root',
                         'port': 22,
                         'passwd': '123456',
                         'pkey_file': '',
                         'host': ''

                         }
    config['default'] = {'conf_path': CONF_PATH,
                         'log_path': LOG_PATH,
                         'fork': 5
                         }
    if not os.path.exists(CONF_PATH):  # 判断配置文件是否存在，不存在创建并写入默认配置
        fp = open(CONF_PATH, 'w')
        config.write(fp)
        fp.close()
    else:
        config.read(CONF_PATH)  # 读取配置文件，获取到分组的options的各项值
        try:
            section = config.sections()
            ip = config.get(group, 'host')
            user = config.get(group, 'user')
            port = config.get(group, 'port')
            passwd = config.get(group, 'passwd')
            pkey_file = config.get(group, 'pkey_file')
            fork = config.get('default', 'fork')
            log_path = config.get('default', 'log_path')
        except Exception:
            print ("group is not exists")
        else:
            return section, ip, user, port, passwd, pkey_file, fork, log_path


def remote_cmd(ip, user, passwd, cmd, pkey_file=None):  # 调用ssh客户端执行命令返回结果
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    if pkey_file:  # 如果传入了密钥文件，采用密钥方式登录
        key = paramiko.RSAKey.from_private_key_file(pkey_file)
        ssh.connect(hostname=ip, username=user, pkey=key)
    ssh.connect(hostname=ip, username=user, password=passwd)
    stdin, stdout, stderr = ssh.exec_command(cmd)
    if stdout:
        result = stdout.read()

    else:
        result = stderr.read()
    return result


'''调用sftp进行上传下载文件'''


class SFTP(object):
    def __init__(self, ip, port, user, passwd, src_file, dst_file, pkey_file=None):
        self.ip = ip
        self.port = int(port)
        self.user = user
        self.passwd = passwd
        self.src_file = src_file
        self.dst_file = dst_file
        self.pkey_file = pkey_file

    def remote_transport(self):
        s = paramiko.Transport((self.ip, self.port))
        if self.pkey_file:  # 如果传入了密钥文件，采用密钥方式登录
            key = paramiko.RSAKey.from_private_key_file(self.pkey_file)
            s.connect(username=self.user, password=None, pkey=key)
        s.connect(username=self.user, password=self.passwd)
        sftp = paramiko.SFTPClient.from_transport(s)
        return sftp

    def get(self):  # 下载文件
        sftp = self.remote_transport()
        sftp.get(self.src_file, self.dst_file)

    def put(self):  # 上传文件
        sftp = self.remote_transport()
        sftp.put(self.src_file, self.dst_file)


'''解析命令行，使用optparse，我用的python3.6版本'''


def opt():
    parser = OptionParser("Usage: %prog [-g GROUP] [-c COMMAND]")
    parser.add_option('-g', '--group',
                      dest='group',
                      action='store',
                      default=True,
                      help='GROUP')
    parser.add_option('-c', '--command',
                      dest='command',
                      action='store',
                      default=True,
                      help="COMMAND")
    options, args = parser.parse_args()
    return options, args


'''根据-c 后面跟的命令判断是进行ssh远程执行命令还是使用sftp上传下载文件操作，并记录日志，src为源文件，dst为目标文件，f是进行get还是put,get表示下载，put表示上传'''


def multi_pool(cmd, ip, user, port, passwd, pkey_file, log_path):
    if cmd.startswith('get') or cmd.startswith('put'):
        src = cmd.split()[1]
        dst = cmd.split()[2]
        f = cmd.split()[0]
        sf = SFTP(ip, port, user, passwd, src, dst, pkey_file)
        if hasattr(sf, f):  # 使用反射，减少判断
            func = getattr(sf, f)
            func()
            logger.loggs("%s %s" % (ip, cmd), log_path)
    else:
        result = remote_cmd(ip, user, passwd, cmd, pkey_file)
        logger.loggs("%s %s" % (ip, cmd), log_path)
        print(result)


'''主函数，进行读取命令行参数以及获取配置文件的各项值，开启多进程，使用进程池'''


def main():
    options, args = opt()
    groups = options.group
    cmd = options.command
    try:
        sec, ip, user, port, passwd, pkey_file, fork, log_file = ConfigParser(groups)
    except Exception:
        print("configparser error")
    else:
        p = Pool(int(fork))
        if groups in sec:
            for i in ip.split(','):
                p.apply_async(func=multi_pool, args=(cmd, i, user, port, passwd, pkey_file, log_file))
            p.close()
            p.join()


if __name__ == '__main__':
    main()