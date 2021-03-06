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

if [ -e /etc/resolv.conf ]
then
  echo -----------
  echo resolv.conf
  echo -----------
  awk '$1=="nameserver" {print $2}' /etc/resolv.conf
fi

if which dlite > /dev/null 2>&1 && pgrep dlite > /dev/null 2>&1
then
  echo --------------
  echo docker -dlite-
  echo --------------
  ssh -T docker@local.docker << 'EOF'
  awk '$1=="nameserver" {print $2}' /etc/resolv.conf
EOF
fi

if which docker-machine >/dev/null 2>&1 && docker-machine ls -filter state=Running | grep -q "^$docker_machine_name"
then
  echo --------------
  echo docker-machine
  echo --------------
  docker-machine ssh $docker_machine_name << 'EOF'
    awk '$1=="nameserver" {print $2}' /etc/resolv.conf
EOF
fi

echo ------------
echo networksetup
echo ------------

sudo networksetup -listallnetworkservices |
sed 1d |
while read iface
do
  echo -n "$iface => "
  sudo networksetup -getdnsservers "$iface"
done
