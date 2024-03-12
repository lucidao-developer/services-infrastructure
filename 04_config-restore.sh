#!/bin/bash

# Configuration
RESTORE_TMP_PATH="/tmp/restore" # Temporary restore path where files are restored
ORIGINAL_COMPOSE_PATH="/mnt/compose" # Original path for Docker Compose files
ORIGINAL_DATA_PATH="/mnt/data" # Original path for other Docker volumes/data

# Move restored Docker Compose files to the original compose directory
# Ensure the original directory is backed up or empty to avoid unwanted overwrites
mv $RESTORE_TMP_PATH/mnt/compose/* $ORIGINAL_COMPOSE_PATH/

# Move other restored data to the original data directory
# Again, ensure this operation is safe to prevent data loss
mv $RESTORE_TMP_PATH/mnt/data/* $ORIGINAL_DATA_PATH/

# Cleanup: Remove the temporary restore directory
rm -rf $RESTORE_TMP_PATH

echo "Data moved to original locations and temporary files cleaned up."
