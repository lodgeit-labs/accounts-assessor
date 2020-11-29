`PP` stands for "Port Postfix". These are the last (probably two or more, as you like), digits in the service's public ports. That is, ports of frontend_server and agraph. This way, you can deploy multiple stacks on one machine. (A stable and dev..)

Because you'll probably want each stack to consist of different images, build.sh takes one parameter, the port, and suffixes names of all images with it. This could maybe be done better with docker labels? idk..

`
../docker_scripts/build.sh 73
`
`
 ../docker_scripts/deploy_stack.sh 73
`

you can also pass additional `INTERNAL_WORKERS_DOCKERFILE_CHOICE` to build.sh. This just selects between the full and the "_hollow" internal_workers images. The "_hollow" one does not copy any sources into the image, and instead relies on you running it with the docker-stack-dev.yml stack, which binds the whole /app/sources directory to your host computer's sources directory, for fast development.


docker-stack-dev.yml is also defined to use the host network, so you can also use `../docker_scripts/run_last_request_in_docker_with_host_net_and_fs.sh`.
