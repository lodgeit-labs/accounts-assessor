def run_last_request_outside_of_docker(self):
	"""
	you should run this script from server_root/
	you should also have `services` running on the host (it doesnt matter that it's simultaneously running in docker), because they have to access files by the paths that `workers` sends them.
	"""
	tmp_volume_data_path = '/var/lib/docker/volumes/robust_tmp/_data/'
	os.system('sudo chmod -R o+rX '+shlex.quote(tmp_volume_data_path))
	last_request_host_path = tmp_volume_data_path + os.path.split(os.readlink(tmp_volume_data_path+'last_request'))[-1]
	local_calculator(last_request_host_path)

"""
>> #PP='' DISPLAY='' RABBITMQ_URL='localhost:5672' REDIS_HOST='redis://localhost' AGRAPH_HOST='localhost' AGRAPH_PORT='10035' REMOULADE_PG_URI='postgresql://remoulade@localhost:5433/remoulade' REMOULADE_API='http://localhost:5005' SERVICES_URL='http://localhost:17788' CSHARP_SERVICES_URL='http://localhost:17789' FLASK_DEBUG='0' FLASK_ENV='production' WATCHMEDO='' ./run_last_request_in_docker_with_host_fs.py --dry_run True --request /app/server_root/tmp/1691798911.3167622.57.1.A52CC96x3070
"""
