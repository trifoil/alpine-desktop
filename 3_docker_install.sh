#!/bin/bash

apk update
apk add docker
apk add docker-compose
rc-update add docker default
/etc/init.d/docker start

read -n 1 -s -r -p "Done. Press any key to continue..."
