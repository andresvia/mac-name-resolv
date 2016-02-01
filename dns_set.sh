#!/bin/bash

docker_machine_name=${DEFAULT_DOCKER_MACHINE_NAME:-boot2docker}

dns_set="${1:-empty}"

if [ "$dns_set"  != "empty" ]
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

  if which dlite > /dev/null 2>&1
  then
    ssh -T docker@local.docker << EOF > /dev/null
    sudo tee /etc/resolv.conf << TEE
    nameserver $dns_set
TEE
EOF
  fi

  if which docker-machine > /dev/null 2>&1
  then
    if docker-machine ls -filter state=running | grep -q "^$docker_machine_name"
    then
      docker-machine ssh $docker_machine_name << EOF > /dev/null
        sudo tee /etc/resolv.conf << TEE
          nameserver $dns_set
TEE
EOF
    fi
  fi
fi

sudo networksetup -listallnetworkservices |
sed 1d |
while read iface
do
  sudo networksetup -setdnsservers "$iface" "$dns_set"
done
