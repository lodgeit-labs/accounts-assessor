#!/usr/bin/env python3
import os

# you should run this script from server_root/
#
# you should also have `services` running on the host (it doesnt matter that it's simultaneously running in docker), because they have to access files by the paths that `workers` sends them.

tmp_volume_data_path = '/var/lib/docker/volumes/robust_tmp/_data/'
os.system('sudo chmod -R o+rX '+tmp_volume_data_path)
last_request_host_path = tmp_volume_data_path + os.path.split(os.readlink(tmp_volume_data_path+'last_request'))[-1]

#os.environ.setdefault('AGRAPH_SECRET_HOST', 'localhost')
#os.environ.setdefault('AGRAPH_SECRET_PORT', '10035')

os.system("""/usr/bin/time  env PYTHONUNBUFFERED=1 ../sources/workers/invoke_rpc_cmdline.py --debug true --halt true -s "http://localhost:7788"  --prolog_flags "set_prolog_flag(services_server,'http://localhost:17788'),set_prolog_flag(die_on_error,false)" 
--dev_runner_options="" """ + last_request_host_path)

