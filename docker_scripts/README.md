# build.sh takes two arguments:

`PP` stands for "Port Postfix". These are the last two (or more, as you like), digits in the service's public ports. That is, ports of frontend_server and agraph. This way, you can deploy multiple stacks on one machine. (A stable and dev..)

Because you'll probably want each stack to consist of different images, build.sh takes PP as firstt parameter, and suffixes names of all images with it. This could maybe be done better with docker labels? idk..

`
../docker_scripts/build.sh 73
`

it also takes optional second argument, `INTERNAL_WORKERS_DOCKERFILE_CHOICE`. This just selects between the full and the "_hollow" internal_workers images. You can pass "_hollow", which points it to internal_workers/Dockerfile_hollow. This mode is useful for development. It does not copy any source code into the image, and instead relies on you running it with one of the "mount_host_sources_dir" stack files.
`
../docker_scripts/build.sh 73 _hollow
`

# deploy_stack.sh

`
 ../docker_scripts/deploy_stack.sh 73 COMPOSE_FILE
`
the "mount_host_sources_dir" stack files bind the whole /app/sources directory to your host computer's sources directory, for fast development.

with "use_host_network", the stack doesn't have its own network. This makes it easy, when the stack is up, to run: `../docker_scripts/run_last_request_in_docker_with_host_net_and_fs.sh`.
