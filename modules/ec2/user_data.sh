#!/bin/sh
​apt update && apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
usermod -aG docker $USER
usermod -aG docker ubuntu
reboot