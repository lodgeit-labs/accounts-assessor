#!/usr/bin/env fish
sudo echo "i'm root!" || { echo "root level setup skipped" && exit 0; }


function _; or status --is-interactive; or exit 1; end


set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"


sudo apt install -y python3 python3-pip;_

# not sure if still needed, maybe was only used for generating password file?
#sudo apt install apache2-utils

# sorry, i do a lot of small scripting with it, as it's my daily shell. But it shouldn't be hard to get by without it, if necessary
sudo apt install -y fish ;_

# for nice building UI
sudo apt install -y tmux;_

# you'll definitely need docker obtained one way or another
which docker; or sudo apt install docker.io golang-docker-credential-helpers;_
sudo usermod -aG docker $USER;_

# compose is a tad more suitable for development than swarm 
which docker-compose; or sudo apt install -y docker-compose;_

# if not using compose:
#docker swarm init;_

echo -e "fs.inotify.max_user_instances=65535\nfs.inotify.max_user_watches=4194304" | sudo tee /etc/sysctl.d/inotify.conf
sudo sysctl --load=/etc/sysctl.d/inotify.conf

