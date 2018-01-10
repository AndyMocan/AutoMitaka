# coding:utf-8
import os ,sys
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)


config_path = os.path.join(BASE_DIR,'Mitaka_L2')
from conf import  settings

controller_ip = settings.host_data['controller_node']
compute_ip = settings.host_data['compute_node']
def parse(config,config_file):
    conf_file = os.path.join(config_path,config_file)
    with open(conf_file,'w') as f:
        for hostname,data in config.items():
            f.write("%s=%s\n" %(hostname,data['IP']))

def parse_run():
    parse(controller_ip,'controller_ip')
    parse(compute_ip,'compute_ip')

def parse2(config,config_file):
    conf_file = os.path.join(config_path,config_file)
    with open(conf_file,'w') as f:
        for hostname,data in config.items():
            if hostname == 'controller':
                pass
            else:
                f.write("%s,%s,%s,%s,%s\n" %(hostname,data['IP'],data['mancard'],data['buscard'],data['tuncard']))

def parse_run2():
    parse2(controller_ip,'controller_ip_netcard')
    parse2(compute_ip,'compute_ip_netcard')
