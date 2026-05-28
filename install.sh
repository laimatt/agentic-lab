#!/bin/bash
set -e

URL="https://github.com/laimatt/agentic-lab/releases/download/v1.0/agentic-lab-mlai-with-rpm.zip"

# Use home directory instead of temp
TMP_DIR="$HOME"
mkdir -p "$TMP_DIR"

echo "Working in $TMP_DIR"

# Ensure dependencies exist
if ! command -v curl >/dev/null 2>&1; then
  sudo dnf install -y curl
fi

if ! command -v unzip >/dev/null 2>&1; then
  sudo dnf install -y unzip
fi

echo "Downloading package..."
curl -fL "$URL" -o "$TMP_DIR/package.zip"

echo "Extracting..."
unzip -o "$TMP_DIR/package.zip" -d "$TMP_DIR"

BASE_DIR="$TMP_DIR/agentic-lab-mlai"

echo "Running system dependencies script..."
chmod +x "$BASE_DIR/agentic-lab/install-system-deps.sh"
yes | sudo "$BASE_DIR/agentic-lab/install-system-deps.sh"

echo "Installing RPMs..."
sudo dnf install -y "$BASE_DIR"/*.rpm

echo "✅ Files preserved at: $TMP_DIR"
echo "✅ Installation complete!"

bobide