#!/usr/bin/env bash

script_dir=$(dirname "$0")
cd "$script_dir"
source "../../xnat.cfg"
docker build -f Dockerfile-add-ldap --build-arg XNAT_VERSION="${xnat_version}"  -t "xnat:${xnat_version}ldap" .

echo "----------------------------"
echo "Change docker-compose.yml to use image xnat:${xnat_version}ldap and restart XNAT (sudo ./restart.sh)"