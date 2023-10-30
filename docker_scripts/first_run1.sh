#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end # this serves as a replacement for the bash "set -e" flag
set DIR (dirname (readlink -m (status --current-filename)));cd "$DIR"


sudo echo "i'm root!"; or begin; echo "root level setup skipped"; exit 0; end



sudo apt install -y python3 python3-pip python3-venv ;_

# for building python packages
sudo apt install -y libcurl4-openssl-dev ;_

# for nice building/deployment UI
sudo apt install -y tmux ;_

# you'll definitely need docker
which docker; or sudo apt install docker.io golang-docker-credential-helpers ;_
sudo usermod -aG docker $USER;_ # fixme, how to apply this without logging out?

# compose is a tad more suitable for development than swarm 
#which docker-compose; or sudo apt install -y docker-compose;_

# if not using compose:
#docker swarm init;_

# bump inotify limits, otherwise, you're gonna get error messages inside docker containers
echo -e "fs.inotify.max_user_instances=65535\nfs.inotify.max_user_watches=4194304" | sudo tee /etc/sysctl.d/inotify.conf
sudo sysctl --load=/etc/sysctl.d/inotify.conf

