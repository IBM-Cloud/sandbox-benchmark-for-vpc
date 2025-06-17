#!/bin/bash

# Use a writable log location
LOG_PATH="/tmp/check_status_output.log"
exec > >(tee -a "$LOG_PATH") 2>&1

set -e

# Assign command-line arguments to variables
LOCAL_KEY_PATH="$LOCAL_KEY_PATH"
BASTION_USER="$BASTION_USER"
BASTION_HOST="$BASTION_HOST"
DASHBOARD_USER="$DASHBOARD_USER"
DASHBOARD_IP="$DASHBOARD_IP"
KEY_NAME="$KEY_NAME"

# Check if the local SSH key file exists
if [ ! -f "$LOCAL_KEY_PATH" ]; then
  echo "Error: SSH key file not found at $LOCAL_KEY_PATH"
  exit 1
fi

# Step 1: Copy SSH key to bastion host
echo "Copying SSH key to bastion host..."
scp -i "$LOCAL_KEY_PATH" -o StrictHostKeyChecking=no "$LOCAL_KEY_PATH" "$BASTION_USER@$BASTION_HOST:/root/$KEY_NAME"

# Step 2: SSH into bastion host, then into dashboard VM, and monitor Docker containers
echo "Connecting to bastion host and monitoring containers on dashboard VM..."
# Remove old host key to avoid verification issues
ssh-keygen -R "$BASTION_HOST" >/dev/null 2>&1


# Modified inner SSH commands with Docker accessibility fixes
ssh -o StrictHostKeyChecking=no -i "$LOCAL_KEY_PATH" "$BASTION_USER@$BASTION_HOST" << EOF
  ssh -o StrictHostKeyChecking=no -i "/root/$KEY_NAME" "$DASHBOARD_USER@$DASHBOARD_IP" << 'INNER_EOF'
    # Load environment settings
    source ~/.bashrc 2>/dev/null || true
    source ~/.profile 2>/dev/null || true
    echo "Waiting for Docker to be installed..."
    while ! docker --version > /dev/null 2>&1; do
      sleep 10
    done
    # Use sudo if needed (common in non-interactive sessions)
    DOCKER_CMD="docker"

    echo "Waiting for Docker to become responsive..."
    while ! \$DOCKER_CMD info &>/dev/null; do
      echo "Docker not responding - daemon might be starting..."
      sleep 10
    done
    echo "Docker is responsive."

    echo "Checking for running containers..."
    while [ \$(\$DOCKER_CMD ps -q | wc -l) -lt 3 ]; do
      echo "Found \$(\$DOCKER_CMD ps -q | wc -l) containers - waiting for three..."
      sleep 10
    done
    echo "Three containers are running:"
    \$DOCKER_CMD ps
INNER_EOF
EOF

# Step 3: Delete the SSH key from bastion host
echo "Cleaning up: Deleting SSH key from bastion host..."
ssh -i "$LOCAL_KEY_PATH" "$BASTION_USER@$BASTION_HOST" "rm /root/$KEY_NAME"
echo "Script completed."
