# coding:utf-8
import logging
'''msg是需要记录的日志信息，f是日志路径'''
def loggs(msg,f):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(f)
    fh.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')   #日志格式
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    logger.info(msg)

if __name__ == '__main__':
    msg = ''
    f = ''
    loggs(msg,f)