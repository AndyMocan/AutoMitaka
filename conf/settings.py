# coding:utf-8

"""配置文件"""

host_data = {
    "controller_node":{    # 控制节点和网络节点
        "controller":{"IP":"172.16.15.90", "username":"root", "password":"root1234", "port":22,"mancard":'eno16780032','buscard':'eno33559296','tuncard':'eno50338560'},
        "controller01":{"IP":"172.16.15.91", "username":"root", "password":"root1234", "port":22,"mancard":'eno16780032','buscard':'eno33559296','tuncard':'eno50338560'},
        "controller02":{"IP":"172.16.15.92", "username":"root", "password":"root1234", "port":22,"mancard":'eno16780032','buscard':'eno33559296','tuncard':'eno50338560'},
        "controller03":{"IP":"172.16.15.93", "username":"root", "password":"root1234", "port":22,"mancard":'eno16780032','buscard':'eno33559296','tuncard':'eno50338560'},
    },

    "compute_node":{    # 计算节点
        "compute01":{"IP":"172.16.15.94", "username":"root", "password":"root1234", "port":22,"mancard":'eno16780032','buscard':'eno33559296','tuncard':'eno50338560'},
        "compute02":{"IP":"172.16.15.95", "username":"root", "password":"root1234", "port":22,"mancard":'eno16780032','buscard':'eno33559296','tuncard':'eno50338560'},
    },

    # "other":{
    #     # "ceilometer":{"IP":"192.168.179.133", "username":"root", "password":"zcl", "port":22},
    # }
}