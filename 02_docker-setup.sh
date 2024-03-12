#!/bin/bash

# Function to display usage
usage() {
    echo "Usage for manager node: $0 manager"
    echo "Usage for worker node: $0 worker SWARM_JOIN_TOKEN MANAGER_IP:PORT"
    exit 1
}

# Check for minimum number of parameters
if [ "$#" -lt 1 ]; then
    usage
fi

NODE_TYPE=$1

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Validate and execute based on the node type
case $NODE_TYPE in
    manager)
        if [ "$#" -ne 1 ]; then
            echo "Error: 'manager' type does not require additional arguments."
            usage
        fi
        ;;
    worker)
        if [ "$#" -ne 3 ]; then
            echo "Error: 'worker' type requires exactly 2 additional arguments: SWARM_JOIN_TOKEN and MANAGER_IP:PORT."
            usage
        fi
        SWARM_JOIN_TOKEN=$2
        MANAGER_IP=$3
        ;;
    *)
        echo "Invalid node type specified. Use 'manager' or 'worker'."
        usage
        ;;
esac

# Update and install necessary packages
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Set up the stable repository
add-apt-repository "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update the package index again and install Docker CE and required plugins
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker to start on boot
systemctl enable docker
systemctl start docker

# Opening necessary ports based on the node type
if [ "$NODE_TYPE" = "manager" ]; then
    # For manager nodes, open ports for Swarm management and Raft consensus
    ufw allow 2377/tcp # Cluster management communications
    ufw allow 7946/tcp # Communication among nodes
    ufw allow 7946/udp # Communication among nodes
    ufw allow 4789/udp # Overlay network traffic

    # Initialize the Swarm (only on the manager node)
    docker swarm init

elif [ "$NODE_TYPE" = "worker" ]; then
    # For worker nodes, open ports for communication among nodes and overlay network traffic
    ufw allow 7946/tcp # Communication among nodes
    ufw allow 7946/udp # Communication among nodes
    ufw allow 4789/udp # Overlay network traffic

    # Join the swarm using the provided token and manager IP
    docker swarm join --token $SWARM_JOIN_TOKEN $MANAGER_IP
else
    # Should never reach here due to earlier checks, but just in case
    echo "An unexpected error occurred."
    exit 1
fi

# Reload UFW to apply the new rules
ufw reload

echo "Docker and Docker Swarm setup for $NODE_TYPE node completed."
