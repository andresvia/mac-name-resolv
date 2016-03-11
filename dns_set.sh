#!/bin/bash

docker_machine_name=${DEFAULT_DOCKER_MACHINE_NAME:-boot2docker}

dns_set="${1:-empty}"
what="${2:-network_service_dns|dlite|docker-machine|networksetup}"
what="^(${what})\$"

if [ "$dns_set"  != "empty" ]
then
  if [[ 'network_service_dns' =~ $what ]]
  then
    scutil <<< "list State:/Network/Service/[^/]+/DNS" |
    while read subkey index eq network_service_dns
    do
      sudo scutil << EOF
        open
        d.init
        d.add ServerAddresses * $dns_set
        set $network_service_dns
        quit
EOF
    done
  fi

  if [[ 'dlite' =~ $what ]]
  then
    if which dlite > /dev/null 2>&1
    then
      ssh -T docker@local.docker << EOF > /dev/null
      sudo tee /etc/resolv.conf << TEE
nameserver $dns_set
TEE
EOF
    fi
  fi

  if [[ 'docker-machine' =~ $what ]]
  then
    if which docker-machine > /dev/null 2>&1
    then
      if docker-machine ls -filter state=Running | grep -q "^$docker_machine_name"
      then
        docker-machine ssh $docker_machine_name << EOF > /dev/null
          sudo tee /etc/resolv.conf << TEE
nameserver $dns_set
TEE
EOF
      fi
    fi
  fi
fi

if [[ 'networksetup' =~ $what ]]
then
  sudo networksetup -listallnetworkservices |
  sed 1d |
  while read iface
  do
    sudo networksetup -setdnsservers "$iface" "$dns_set"
  done
fi
