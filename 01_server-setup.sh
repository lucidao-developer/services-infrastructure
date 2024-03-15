#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# SSH configuration backup
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Remove default overrides
rm /etc/ssh/sshd_config.d/*

# Update sshd_config as needed
echo "Include /etc/ssh/sshd_config.d/*.conf \
# Authentication:\
LoginGraceTime 20\
PermitRootLogin no\
MaxAuthTries 3\
PubkeyAuthentication yes\
\
# To disable tunneled clear text passwords, change to no here!\
PasswordAuthentication no\
PermitEmptyPasswords no\
\
# Change to yes to enable challenge-response passwords (beware issues with\
# some PAM modules and threads)\
ChallengeResponseAuthentication no\
\
# Kerberos options\
KerberosAuthentication no\
\
# GSSAPI options\
GSSAPIAuthentication no\
\
# Set this to 'yes' to enable PAM authentication\
UsePAM no\
\
X11Forwarding no\
PrintMotd no\
PermitUserEnvironment no\
\
# override default of no subsystems\
Subsystem	sftp	/usr/lib/openssh/sftp-server\
DebianBanner no" > /etc/ssh/sshd_config

# Test and reload SSH configuration
sshd -t
systemctl reload sshd.service

# Restart SSH service (optional, as reload should suffice)
service ssh restart

# Firewall setup with UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# Install fail2ban
apt-get install -y fail2ban

# Configure fail2ban as needed
echo "[DEFAULT]\
 bantime = 8h\
 ignoreip =\
 ignoreself = true\
\
 [sshd]\
 enabled = true" > /etc/fail2ban/jail.local
# Restart fail2ban service
service fail2ban restart

# Add a new user and grant sudo privileges
adduser --disabled-password --gecos "" alesauro
echo "alesauro:password" | chpasswd  # Replace 'password' with a secure password of your choice
usermod -aG sudo alesauro

# Setup SSH keys for the new user
mkdir -p /home/alesauro/.ssh
# Add the public key to /home/alesauro/.ssh/authorized_keys
# echo "public_key_string" > /home/alesauro/.ssh/authorized_keys

# Adjust permissions for SSH directory and files
chown -R alesauro:alesauro /home/alesauro/.ssh
chmod 700 /home/alesauro/.ssh
# chmod 600 /home/alesauro/.ssh/authorized_keys

# Install basic system utilities
apt-get install -y ca-certificates curl net-tools

# Docker installation steps (34-38) are part of step 2 in your plan and hence omitted here
# The Docker installation and Swarm setup will be addressed in a separate script

echo "Basic server setup completed."
