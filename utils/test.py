import os

local_dir = '/smb/dev/AutoMitaka'
remote_dir = '/root/openstack-mitaka'
for root, dirs, files in os.walk(local_dir):
    # print('root:%s\ndirs:%s\nfiles:%s\n' %(root,dirs,files))
    for filespath in files:
        local_file = os.path.join(root, filespath)
        # a = local_file.replace(local_dir, '')
        # print('==============%s' %(a))
        # print(local_file)
        remote_file = os.path.join(remote_dir, filespath)
        for name in dirs:
            local_path = os.path.join(root, name)
            # print(local_path)
            a = local_path.replace(local_dir, '')
            remote_path = os.path.join(remote_dir, name)
            print(remote_path)