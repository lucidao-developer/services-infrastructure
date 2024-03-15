#!/bin/bash

#ensure a free partition /dev/sda2 exists

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "# docker swarm private network \
10.0.0.3 server1 \
10.0.0.2 server2 \
10.0.0.1 server3" >> /etc/hosts

add-apt-repository ppa:gluster/glusterfs-9
apt-get update
apt-get install glusterfs-server -y

systemctl start glusterd
systemctl enable glusterd

mkfs.xfs /dev/sda2

mkdir -p /mnt/shared
chown nobody:nogroup /mnt/shared
chmod 777 /mnt/shared

echo "/dev/sda2 /mnt/shared xfs defaults 0 0" >> /etc/fstab

mount -a

# These are the ports needed to work with gluster, but you can think about only opening to internal network
ufw allow 24007/tcp
ufw allow 24007/udp
ufw allow 24008/tcp
ufw allow 24008/udp
ufw allow 24009/tcp
ufw allow 24009/udp

ufw allow 49152/tcp
ufw allow 49152/udp

ufw allow 49153/tcp
ufw allow 49153/udp

ufw allow 49154/tcp
ufw allow 49154/udp

ufw allow 49155/tcp
ufw allow 49155/udp

ufw allow 49156/tcp
ufw allow 49156/udp

ufw reload


# after running the command up in the other servers run this on server1
gluster peer probe server2
gluster peer probe server3

# again on all servers
mkdir -p /mnt/shared/vol1

# then only on one
gluster volume create vol1 replica 3 server1:/mnt/shared/vol1 server2:/mnt/shared/vol1 server3:/mnt/shared/vol1 force
gluster volume start vol1

# again on all servers
echo "localhost:/vol1 /mnt/public glusterfs defaults,_netdev 0 0" >> /etc/fstab
mount -a

# where resideds data
cp -r /mnt/data /mnt/public/data




echo "Gluster setup completed successfully."