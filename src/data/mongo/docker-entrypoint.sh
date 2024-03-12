#!/bin/bash
echo "Changing keyfile ownership to mongodb:mongodb"
chown mongodb:mongodb /etc/mongo/mongodb-keyfile
chmod 400 /etc/mongo/mongodb-keyfile
exec docker-entrypoint.sh "$@"