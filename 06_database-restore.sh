#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Configuration variables
MGOB_CONTAINER_NAME="mgob"  # Name of the mgob container
S3_BUCKET_URL="s3://yourbucketname/path/to/backup"  # S3 URL to the backup file
BACKUP_FILE_NAME="mongo-backup.gz"  # Name of the backup file
LOCAL_STORAGE_PATH="/storage"  # Local storage path inside the mgob container

# Prompt for MongoDB credentials
read -p "Enter MongoDB username: " db_user
read -sp "Enter MongoDB password: " db_password
echo

# MongoDB connection string
MONGODB_HOST="mongodb://${db_user}:${db_password}@lucidao-rewarder-db1:27017,lucidao-rewarder-db2:27017,lucidao-rewarder-db3:27017/lucidao-rewarder-db?authSource=admin"

# Step 1: Download the backup file from S3 to the mgob container
echo "Downloading the backup file from S3 to the mgob container..."
docker exec $MGOB_CONTAINER_NAME sh -c "wget -O $LOCAL_STORAGE_PATH/$BACKUP_FILE_NAME '$S3_BUCKET_URL'"

# Step 2: Restore the MongoDB backup from the downloaded file
echo "Restoring MongoDB backup..."
docker exec $MGOB_CONTAINER_NAME sh -c "mongorestore --gzip --archive=$LOCAL_STORAGE_PATH/$BACKUP_FILE_NAME --uri '$MONGODB_HOST' --drop"

echo "MongoDB restoration process completed."
