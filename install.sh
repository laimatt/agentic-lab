#!/bin/bash
set -e

URL="https://github.com/laimatt/agentic-lab/releases/download/v1.0/agentic-lab-mlai-with-rpm.zip"

TMP_DIR=$(mktemp -d)

echo "Working in $TMP_DIR"

# Ensure dependencies exist
command -v curl >/dev/null || sudo dnf install -y curl
command -v unzip >/dev/null || sudo dnf install -y unzip

echo "Downloading package..."
curl -L "$URL" -o "$TMP_DIR/package.zip"

echo "Extracting..."
unzip -o "$TMP_DIR/package.zip" -d "$TMP_DIR"

# Path to extracted content
BASE_DIR="$TMP_DIR/agentic-lab-mlai-with-rpm"

echo "Running system dependencies script..."
chmod +x "$BASE_DIR/agentic-lab-mlai/install-system-deps.sh"
sudo "$BASE_DIR/agentic-lab-mlai/install-system-deps.sh"

echo "Installing RPMs..."
sudo dnf install -y "$BASE_DIR"/*.rpm

echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "✅ Installation complete!"
``
