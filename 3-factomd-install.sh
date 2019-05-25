#!/bin/bash

# Testnet Version
# echo "Please specify required version"
# echo "Latest releases here: https://hub.docker.com/r/factominc/factomd/tags"
# read -p "Factom docker version (eg v6.2.2-alpine): " version

# Preset version initially
version="v6.3.1-rc1-alpine"

# Set iptables
iptables -A INPUT ! -s 54.171.68.124/32 -p tcp -m tcp --dport 2376 -m conntrack --ctstate NEW,ESTABLISHED -j REJECT --reject-with icmp-port-unreachable
iptables -A DOCKER-USER ! -s 54.171.68.124/32  -i eth0 -p tcp -m tcp --dport 8090 -j REJECT --reject-with icmp-port-unreachable
iptables -A DOCKER-USER ! -s 54.171.68.124/32  -i eth0 -p tcp -m tcp --dport 2222 -j REJECT --reject-with icmp-port-unreachable
iptables -A DOCKER-USER ! -s 54.171.68.124/32  -i eth0 -p tcp -m tcp --dport 8088 -j REJECT --reject-with icmp-port-unreachable
iptables -A DOCKER-USER ! -s 178.62.125.252/32  -i eth0 -p tcp -m tcp --dport 8088 -j REJECT --reject-with icmp-port-unreachable
iptables -A DOCKER-USER -p tcp -m tcp --dport 8110 -j ACCEPT


# Set Firewall persistence
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt -y install iptables-persistent


# Docker Swarm Keys
mkdir -p /etc/docker 
wget https://raw.githubusercontent.com/FactomProject/factomd-testnet-toolkit/master/tls/cert.pem -O /etc/docker/factom-testnet-cert.pem 
wget https://raw.githubusercontent.com/FactomProject/factomd-testnet-toolkit/master/tls/key.pem -O /etc/docker/factom-testnet-key.pem 
chmod 644 /etc/docker/factom-testnet-cert.pem
chmod 440 /etc/docker/factom-testnet-key.pem
chgrp docker /etc/docker/*.pem


# Configure Docker
printf '{
  "tls": true,
  "tlscert": "/etc/docker/factom-testnet-cert.pem",

  "tlskey": "/etc/docker/factom-testnet-key.pem",
  "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"]
}' >> /etc/docker/daemon.json

mkdir /etc/systemd/system/docker.service.d

printf "[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
" > /etc/systemd/system/docker.service.d/override.conf


# Restart and check daemon is running
systemctl daemon-reload
sleep 2
systemctl restart docker
sleep 2
systemctl status docker


# Docker Volumes
docker volume create factom_database
docker volume create factom_keys


# Join Swarm
docker swarm join --token SWMTKN-1-0bv5pj6ne5sabqnt094shexfj6qdxjpuzs0dpigckrsqmjh0ro-87wmh7jsut6ngmn819ebsqk3m 54.171.68.124:2377


# Google form to join fct.tools monitoring
# https://docs.google.com/forms/d/e/1FAIpQLSd-t33chnGOyLZ6kJ-QC-L0EgOExzY7GQ8y9e0I0E4AIbdKBQ/viewform


# Get factomd.conf file and move into docker volume
wget -O factomd.conf \
https://raw.githubusercontent.com/FactomProject/factomd-testnet-toolkit/master/factomd.conf.EXAMPLE
mv factomd.conf /var/lib/docker/volumes/factom_keys/_data/factomd.conf


# Start testnet factomd
docker run -d --name "factomd" \
			-v "factom_database:/root/.factom/m2" \
			-v "factom_keys:/root/.factom/private" \
			--restart unless-stopped \
			-p "8088:8088" \
			-p "8090:8090" \
			-p "8110:8110" \
			-l "name=factomd" \
			factominc/factomd:$version \
			-broadcastnum=16 \
			-network=CUSTOM \
			-customnet=fct_community_test \
			-startdelay=600 \
			-faulttimeout=120 \
			-config=/root/.factom/private/factomd.conf
			