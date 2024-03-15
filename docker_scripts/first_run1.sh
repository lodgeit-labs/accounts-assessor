#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end # this serves as a replacement for the bash "set -e" flag
set DIR (dirname (readlink -m (status --current-filename)));cd "$DIR"


sudo echo "i'm root!"; or begin; echo "root level setup skipped"; exit 0; end



sudo apt install -y python3 python3-pip python3-venv ;e

# for building python packages
sudo apt install -y libcurl4-openssl-dev ;e

# for nice building/deployment UI
sudo apt install -y tmux ;e

# you'll definitely need docker
which docker; or sudo apt install docker.io golang-docker-credential-helpers ;e
sudo usermod -aG docker $USER ;e # fixme, how to apply this without logging out?

# compose is a tad more suitable for development than swarm 
which docker-compose; or ./first_run1c.sh; e
docker-compose version;e
#sudo apt install -y docker-compose ;e



# if not using compose:
#docker swarm init ;e

# bump inotify limits, otherwise, you're gonna get error messages inside docker containers
echo -e "fs.inotify.max_user_instances=65535\nfs.inotify.max_user_watches=4194304" | sudo tee /etc/sysctl.d/inotify.conf
sudo sysctl --load=/etc/sysctl.d/inotify.conf

