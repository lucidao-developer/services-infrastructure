#!/bin/bash
echo "Running entrypoint.sh script..."
set -e

until mongosh --eval "db.adminCommand('ping').ok" > /dev/null 2>&1; do
  echo "Waiting for MongoDB to be ready..."
  sleep 2
done


# Function to initialize replica set
initialize_replica_set() {
  echo "Initializing replica set"
  mongosh --eval 'rs.initiate({_id: "rs0", members: [{_id: 0, host: "lucidao-rewarder-db1:27017"}, {_id: 1, host: "lucidao-rewarder-db2:27017"}, {_id: 2, host: "lucidao-rewarder-db3:27017"}]})'

  # Wait for the replica set to initialize
  sleep 20

  # Create MongoDB user
  echo "Creating MongoDB user"
  mongosh admin --eval 'db.createUser({user: "lucidao-user", pwd: "LucidaoRewarder2024!", roles: [{role: "readWriteAnyDatabase", db: "admin"}]})'
}

# Check if replica set is already initialized
if [ "$(mongosh --eval "rs.status().ok" | tail -n 1)" == "1" ]; then
  echo "Replica set already initialized"
else
  initialize_replica_set
fi

# Keep the container running
tail -f /dev/null