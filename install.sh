#!/bin/bash
set -e

LAB_NAME="agentic-lab"
# Use home directory instead of temp

echo "Working in $HOME"

# Ensure dependencies exist
if ! command -v curl >/dev/null 2>&1; then
  sudo dnf install -y curl
fi

# if ! command -v unzip >/dev/null 2>&1; then
#   sudo dnf install -y unzip
# fi


git clone --depth 1 --filter=blob:none --sparse https://github.com/laimatt/agentic-lab.git
cd agentic-lab
git sparse-checkout set agentic-lab

echo "Running system dependencies script..."
chmod +x "$HOME/$LAB_NAME/install-system-deps.sh"
yes | sudo "$HOME/$LAB_NAME/install-system-deps.sh"

# Check if bobide command already exists
if command -v bobide >/dev/null 2>&1; then
  echo "bobide command already exists, skipping RPM installation..."
else
  URL="https://github.com/laimatt/agentic-lab/releases/download/v2.0/IBM-Bob-linux-x64-1.109.5+bob1.0.2.rpm"

  cd "$HOME"
  curl -fL -O "$URL" || {
    echo "Failed to download package.zip"
    exit 1
  }

  echo "Installing RPMs..."
  sudo rpm -ivh "$HOME"/*.rpm || \
  sudo dnf install -y "$HOME"/*.rpm
fi

echo "✅ Files preserved at: $HOME"

# Create 20 users with password "pass"
echo "Creating users..."
for i in $(seq -w 1 20); do
  USERNAME="user$i"
  if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists, skipping..."
  else
    sudo useradd -m "$USERNAME"
    echo "$USERNAME:pass" | sudo chpasswd
    echo "Created user: $USERNAME"
  fi

  # Check if lab directory already exists in user's home
  if [ -d "/home/$USERNAME/$LAB_NAME" ]; then
    echo "$LAB_NAME directory already exists for $USERNAME, skipping copy..."
  else
    echo "Copying $LAB_NAME to $USERNAME's home directory..."
    sudo cp -r /home/itzuser/$LAB_NAME /home/$USERNAME/
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/$LAB_NAME
  fi
  
done

echo "✅ Installation complete!"
