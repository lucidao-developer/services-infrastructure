#!/bin/bash

# Configuration
TEMP_DUPLICATI_CONTAINER="temp-duplicati"
S3_BUCKET_URL="s3://yourbucketname/path/to/backup"
RESTORE_PATH="/tmp/restore" # Temporary restore path on the host
ENCRYPTION_PASSPHRASE="yourEncryptionPassphrase" # Consider prompting for this securely instead of hardcoding

# Deploy a temporary Duplicati container
docker run --name $TEMP_DUPLICATI_CONTAINER -v $RESTORE_PATH:/restore linuxserver/duplicati

# Wait for Duplicati to initialize (adjust time as needed)
echo "Waiting for Duplicati to initialize..."

# Wait for Duplicati's web UI to become available
echo "Waiting for Duplicati to become available..."
sleep 30
until $(curl --output /dev/null --silent --head --fail http://localhost:8200); do
    printf '.'
    sleep 5
done
echo "Duplicati is now available."

# Securely prompt for decryption passphrase
echo -n "Enter decryption passphrase: "
read -s ENCRYPTION_PASSPHRASE

# Restore the backup
docker exec $TEMP_DUPLICATI_CONTAINER \
    duplicati-cli restore $S3_BUCKET_URL \
    --restore-path=/restore \
    --passphrase="$ENCRYPTION_PASSPHRASE" \
    --no-encryption=true

echo "Set docker secrets before deploying the services"
# Define your secrets here
declare -a secrets=("ALCHEMY_API_KEY" "ALCHEMY_APP_ID" "AUTHELIA_JWT_SECRETS" "AUTHELIA_NOTIFIER_SMTP_PASSWORD" "AUTHELIA_SESSION_SECRET" "AUTHELIA_STORAGE_ENCRYPTION_KEY" "BACKEND_SECRET_KEY" "JWT_SECRET" "MONGODB_PASSWORD" "PRIVATE_KEY")

# Loop through the secrets array
for secret_name in "${secrets[@]}"
do
    # Prompt for the secret value
    read -sp "Enter the value for $secret_name: " secret_value
    echo

    # Create a temporary file to hold the secret value
    secret_file=$(mktemp)

    # Write the secret value to the file
    echo "$secret_value" > "$secret_file"

    # Create the secret in Docker Swarm
    docker secret create "$secret_name" "$secret_file"

    # Remove the temporary file
    rm "$secret_file"

    # Clear the secret value variable
    unset secret_value
done

echo "All secrets have been set successfully."

# Redeploy services using the restored Docker Compose files
for compose_file in $RESTORE_PATH/*.yml; do
    STACK_NAME=$(basename "$compose_file" .yml)
    docker stack deploy -c "$compose_file" "$STACK_NAME"
done

# Cleanup: Stop and remove the temporary Duplicati container
docker stop $TEMP_DUPLICATI_CONTAINER
docker rm $TEMP_DUPLICATI_CONTAINER

echo "Restoration process completed."
