#!/bin/bash

docker_machine_name=${DEFAULT_DOCKER_MACHINE_NAME:-boot2docker}

echo -------------------
echo network_service_dns
echo -------------------
scutil <<< "list State:/Network/Service/[^/]+/DNS" |
while read subkey index eq network_service_dns
do
  sudo scutil << EOF
    open
    get $network_service_dns
    d.show
    quit
EOF
done

echo -----------
echo resolv.conf
echo -----------
awk '$1=="nameserver" {print $2}' /etc/resolv.conf

if which dlite > /dev/null 2>&1
then
  echo --------------
  echo docker -dlite-
  echo --------------
  ssh -T docker@local.docker << 'EOF'
  awk '$1=="nameserver" {print $2}' /etc/resolv.conf
EOF
fi

if docker-machine ls -filter state=running | grep -q "^$docker_machine_name"
then
  echo --------------
  echo docker-machine
  echo --------------
  docker-machine ssh $docker_machine_name << 'EOF'
    awk '$1=="nameserver" {print $2}' /etc/resolv.conf
EOF
fi

echo -----------------------------
echo networksetup ethernet - wi-fi
echo -----------------------------

sudo networksetup -getdnsservers 'ethernet'
sudo networksetup -getdnsservers 'wi-fi'
