# Service infrastructure

## Docker Swarm Architecture Guide with Traefik and Backup Solutions

This comprehensive guide delves into the architecture of Docker Swarm, focusing on scalability, security, and ease of management for containerized applications. It highlights the integration of Traefik for advanced routing and load balancing, and outlines robust backup strategies essential for data integrity and disaster recovery.

### Core Components of Docker Swarm

Docker Swarm transforms a group of Docker hosts into a single, virtual Docker host, emphasizing the following core components:

- Manager Nodes: Orchestrate and schedule containers, maintain the desired state, and manage Swarm operations.
- Worker Nodes: Execute the containers as per the manager nodes' assignments and report their status.

### Enhancing Swarm with Traefik

Traefik seamlessly integrates with Docker Swarm to enhance service discovery and load balancing:

- Automatic Service Discovery: Traefik dynamically detects services deployed in the Swarm, eliminating manual configuration.
- Seamless Load Balancing: Efficiently distributes incoming requests across service instances, ensuring high availability and responsiveness.
- SSL Support: Facilitates SSL termination and automatic SSL certificate generation with Let's Encrypt for secure communications.
- Deploying Traefik within Docker Swarm involves defining it as a service in a Docker Compose file, utilizing service labels for routing configurations.

### Implementing Comprehensive Backup Solutions

A multi-faceted backup strategy is vital for safeguarding data and ensuring quick recovery:

- Volume Backups: Tools like restic or custom scripts can automate backups of Docker volumes to various storage backends, including cloud services like AWS S3.
- Database Backups: Leverage database-specific tools (e.g., pg_dump for PostgreSQL) to create consistent database backups, incorporating both full and incremental backup strategies.
- Configurations and Secrets: While Docker secrets are secure within Swarm, external backups of critical configurations and secret values are advisable, ensuring encryption and secure storage.
  For database backups within the Swarm, solutions like mgob offer automated, scheduled backups for MongoDB, supporting storage options like S3 and features like incremental backups.

### Backup and Traefik Configuration in Docker Swarm

To effectively integrate Traefik and backup solutions:

- Traefik Setup: Deploy Traefik as a service, configuring it to auto-discover and route traffic to your Swarm services.
- Backup Tool Configuration: Select and set up appropriate backup tools tailored to your data and application needs, ensuring regular and reliable backups.
- Operational Testing: Regularly test the configuration, routing capabilities of Traefik, and the reliability of your backup and restoration processes to ensure operational readiness.
- This guide not only outlines the foundational aspects of Docker Swarm but also emphasizes the importance of Traefik for efficient routing and load balancing, along with the critical role of comprehensive backup strategies in maintaining data integrity and supporting disaster recovery efforts.

For more detailed guidance on configuring Traefik and setting up backup solutions within Docker Swarm, explore the official Docker documentation, Traefik documentation, and resources on backup tools like restic and mgob.

## Docker Swarm Restoration Guide

This guide provides detailed instructions on how to restore your Docker Swarm environment from encrypted backups stored in an S3-compatible storage. The process is divided into four main scripts, each serving a specific purpose in the restoration workflow.

### Script Descriptions

- 01_server-setup.sh: Prepares the server with essential security configurations, including SSH settings, firewall rules, and installing Fail2Ban. It also creates a new user with sudo privileges.

- 02_docker-setup.sh: Installs Docker and initializes Docker Swarm. It configures the node as either a manager or a worker based on the parameters provided and opens necessary ports on the firewall.

- 03_temp-config-restore.sh: Deploys a temporary Duplicati container to restore configurations and data from the backup stored in S3. It waits for Duplicati to become available before proceeding with the restoration.

- 04_config-restore.sh: Moves the restored configurations and data from a temporary path to their original locations and cleans up temporary files.

- 05_database-restore.sh: Restores MongoDB databases from backups stored in S3, using mgob container.

### Restoration Process

#### Step 1: Base Server Setup

Run 01_server-setup.sh as root to prepare the server. This script secures SSH access and sets up basic security measures.

```bash
sudo ./01_server-setup.sh
```

#### Step 2: Docker and Swarm Configuration

Execute 02_docker-setup.sh as root to install Docker and configure the node. Specify the node type (manager or worker) and, if it's a worker, provide the Swarm join token and manager IP.

- For a manager node:

```bash
sudo ./02_docker-setup.sh manager
```

- For a worker node:

```bash
sudo ./02_docker-setup.sh worker SWARM_JOIN_TOKEN MANAGER_IP:PORT
```

#### Step 3: Temporary Configuration Restoration

Deploy a temporary Duplicati container and restore the backup from S3 using 03_temp-config-restore.sh. This script requires Duplicati to be accessible and might need adjustments based on your Duplicati setup.

```bash
./03_temp-config-restore.sh
```

Note: Adjust S3_BUCKET_URL in the script to your actual S3 bucket path. The script will wait for Duplicati's web UI to become available before proceeding with the restoration.

#### Step 4: Final Configuration Restoration

After verifying the restored data, run 04_config-restore.sh to move the data to its original locations. This script should be executed with caution to avoid data loss.

```bash
./04_config-restore.sh
```

Note: Ensure the paths ORIGINAL_COMPOSE_PATH and ORIGINAL_DATA_PATH in the script match your environment's actual paths.

#### Step 5: MongoDB Database Restoration

Ensure restore_mongodb.sh is on a Docker Swarm node with Docker and mgob container access.
Execute the script. You'll be prompted for MongoDB credentials.

```bash
sudo ./05_database-restore.sh
```

Note: Before running restore_mongodb.sh, ensure to customize the script according to your needs:

- S3 Bucket URL: Modify the S3_BUCKET_URL variable in the script to point to the location of your MongoDB backups in the S3 bucket.
- MGOB Container Name: If your mgob container is named differently, update the MGOB_CONTAINER_NAME variable accordingly.
- MongoDB Credentials: The script will prompt for the MongoDB username and password. These credentials should have the necessary permissions for the restoration process.
- MongoDB Hosts: Adjust the MongoDB connection string in the script to match your MongoDB replica set configuration, including all member hosts and the target database.
- Backup File Name: If your backup file naming convention differs, modify the BACKUP_FILE_NAME variable to match your backup files stored in S3.

### Important Considerations

Data Verification: Manually verify the restored data in the temporary location before moving it to the original paths.
Backup: Ensure you have current backups or copies of important data before overwriting anything.
Customization: You might need to customize the scripts to match your specific environment, backup structure, and Docker Swarm setup.
Security: Handle sensitive information, such as decryption passphrases and access credentials, securely throughout the process.
This guide outlines a structured approach to restoring your Docker Swarm environment from backups. Adjust the scripts and steps as necessary to fit your specific setup and requirements.
