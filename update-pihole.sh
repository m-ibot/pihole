#!/bin/bash

# --- CONFIGURATION ---
# Define the absolute path to the directory containing your docker-compose.yml
COMPOSE_DIR="$HOME/pihole"

# Define the image name exactly as it appears in your docker-compose.yml
IMAGE_NAME="pihole/pihole:latest"
# ---------------------

# 1. Navigate to the compose directory
cd "$COMPOSE_DIR" || { echo "Error: Could not navigate to $COMPOSE_DIR"; exit 1; }

echo "[i] Checking for Pi-hole updates..."

# 2. Get the unique ID of the current image (errors suppressed if it doesn't exist yet)
OLD_IMAGE_ID=$(podman image inspect "$IMAGE_NAME" --format '{{.Id}}' 2>/dev/null)

# 3. Execute the pull command
echo "[i] Pulling latest image via podman-compose..."
podman-compose pull

# 4. Get the unique ID of the image after the pull
NEW_IMAGE_ID=$(podman image inspect "$IMAGE_NAME" --format '{{.Id}}' 2>/dev/null)

# 5. Compare the IDs and conditionally restart
if [ "$OLD_IMAGE_ID" != "$NEW_IMAGE_ID" ] || [ -z "$OLD_IMAGE_ID" ]; then
    echo "[!] New Pi-hole image detected! Restarting the container..."
    podman-compose down
    podman-compose up -d

    echo "[i] Cleaning up old, unused images to save disk space..."
    podman image prune -f

    echo "[✓] Pi-hole update complete."
else
    echo "[✓] No new updates found. Pi-hole is already up to date. Skipping restart."
fi
