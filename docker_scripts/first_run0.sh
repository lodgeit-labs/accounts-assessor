#!/usr/bin/env bash
sudo echo "i'm root!" || { echo "root level setup skipped" && exit 0; }
sudo apt update
sudo apt install -y fish
