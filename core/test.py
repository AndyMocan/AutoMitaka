# coding:utf-8

import multiprocessing
import time

def run(*args):
    print 'run.........%s' %(args)
    time.sleep(5)
    print('end..........%s' %(args))




for i in xrange(5):
    p = multiprocessing.Process(target=run, args=('hello',))
    p.start()
    p.join()