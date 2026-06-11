#!/bin/bash
set -e

# ============================================
# CONFIGURATION - Edit these values as needed
# ============================================
LAB_NAME="agentic-lab"
LAB_REPO="https://github.com/laimatt/agentic-lab.git"
LAB_BRANCH="additional-labs"
USER_PASSWORD="pass"
USER_RANGE_START=1
USER_RANGE_END=3
USER_PREFIX="user"
BOBIDE_RPM_URL="https://github.com/laimatt/agentic-lab/releases/download/v2.0/IBM-Bob-linux-x64-1.109.5+bob1.0.2.rpm"
BOBIDE_WRAPPER_PATH="/usr/local/bin/bobide-no-keyring"
BOBIDE_DESKTOP_NAME="IBM Bob"
SCREEN_BLANK_TIMEOUT=14400  # 4 hours in seconds
FAVORITE_APPS="['firefox.desktop', 'org.gnome.Nautilus.desktop', 'bobide.desktop', 'org.gnome.Terminal.desktop']"

echo "Working in $HOME"

# ============================================
# FUNCTION: Create wrapper script (system-wide)
# ============================================
create_bobide_wrapper() {
    echo "Creating system-wide wrapper script..."
    
    # Create the wrapper script
    sudo bash -c "cat > '$BOBIDE_WRAPPER_PATH'" << 'EOF'
#!/bin/bash
# Wrapper script for bobide to suppress keyring notifications
# Forces basic password storage

# If a directory path is provided, ensure it's treated as a folder
if [ -d "$1" ]; then
    # Launch bobide with the directory and disable keyring
    exec /usr/share/bobide/bobide --password-store="basic" "$1"
else
    # Launch bobide normally with any other arguments
    exec /usr/share/bobide/bobide --password-store="basic" "$@"
fi
EOF
    
    # Make it executable by all users (755)
    sudo chmod 755 "$BOBIDE_WRAPPER_PATH"
    
    echo "✓ Wrapper script created at $BOBIDE_WRAPPER_PATH"
}


# ============================================
# FUNCTION: Configure system-wide dconf defaults
# ============================================
configure_system_dconf() {
    echo "Configuring system-wide dconf defaults..."
    
    # 1. Create dconf profile if it doesn't exist
    if [ ! -f /etc/dconf/profile/user ]; then
        sudo mkdir -p /etc/dconf/profile
        sudo bash -c 'cat > /etc/dconf/profile/user' << 'EOF'
user-db:user
system-db:local
EOF
        echo "  ✓ Created dconf profile"
    else
        echo "  ✓ dconf profile already exists"
    fi
    
    # 2. Create system defaults directory
    sudo mkdir -p /etc/dconf/db/local.d
    
    # 3. Set default favorites for all new users
    sudo bash -c "cat > /etc/dconf/db/local.d/01-favorites" << EOF
# Default favorite applications for all users
[org/gnome/shell]
favorite-apps=$FAVORITE_APPS
EOF
    echo "  ✓ Configured default favorites"
    
    # 4. Set default power settings for all new users
    sudo bash -c "cat > /etc/dconf/db/local.d/02-power" << EOF
# Extend screen blank timeout (configured in script variables)
[org/gnome/desktop/session]
idle-delay=uint32 $SCREEN_BLANK_TIMEOUT
EOF
    echo "  ✓ Configured power settings (4 hours screen blank)"
    
    # 5. Disable GNOME Initial Setup and Tour (Welcome to Red Hat popup)
    sudo bash -c 'cat > /etc/dconf/db/local.d/03-initial-setup' << 'EOF'
# Disable GNOME Initial Setup welcome screen
[org/gnome/initial-setup]
had-user-interaction=true

# Disable GNOME Tour ("check out the tour" popup)
[org/gnome/shell]
welcome-dialog-last-shown-version='999.0'
EOF
    echo "  ✓ Disabled GNOME Initial Setup and Tour"
    
    # 6. Compile the database
    sudo dconf update
    echo "  ✓ dconf database compiled"
    
    echo "✓ System-wide dconf defaults configured"
}

# ============================================
# FUNCTION: Configure bobide notifications
# ============================================
configure_bobide_notifications() {
    local USERNAME="$1"
    local USER_HOME="/home/$USERNAME"
    
    echo "  → Configuring bobide for user: $USERNAME"
    
    # Define paths - Note: IBM Bob uses "IBM Bob" directory name
    local SETTINGS_DIR="$USER_HOME/.config/IBM Bob/User"
    local SETTINGS_FILE="$SETTINGS_DIR/settings.json"
    local BASHRC="$USER_HOME/.bashrc"
    
    # Create settings directory (need to handle space in directory name)
    sudo -u "$USERNAME" mkdir -p "$SETTINGS_DIR"
    
    # NOTE: Power settings are configured system-wide via dconf (see configure_system_dconf function)
    # Per-user gsettings/dconf attempts here won't work because user isn't logged in yet
    
    # Create settings.json to disable notifications, welcome screen, and trust prompts
    sudo -u "$USERNAME" bash -c "cat > '$SETTINGS_FILE'" << 'EOF'
{
    "update.mode": "none",
    "update.showReleaseNotes": false,
    "extensions.autoCheckUpdates": false,
    "extensions.autoUpdate": false,
    "extensions.ignoreRecommendations": true,
    "extensions.showRecommendationsOnlyOnDemand": true,
    "telemetry.telemetryLevel": "off",
    "workbench.startupEditor": "none",
    "workbench.welcomePage.walkthroughs.openOnInstall": false,
    "security.workspace.trust.enabled": false,
    "security.workspace.trust.startupPrompt": "never",
    "security.workspace.trust.emptyWindow": false
}
EOF
    
    # Add environment variables to .bashrc if not already present
    # NOTE: These are redundant with the wrapper script's --password-store="basic" flag
    # but kept as defense-in-depth for terminal launches
    if ! grep -q "VSCODE_SKIP_KEYRING" "$BASHRC" 2>/dev/null; then
        sudo -u "$USERNAME" bash -c "cat >> '$BASHRC'" << 'EOF'

# bobide notification suppression - disable keyring completely
# NOTE: Redundant with wrapper script, but kept as backup
export VSCODE_SKIP_KEYRING=1
export ELECTRON_NO_ATTACH_CONSOLE=1
export GNOME_KEYRING_CONTROL=/dev/null
export PASSWORD_STORE_DIR=/dev/null
EOF
    fi
    
    # Also add to .bash_profile for login shells
    local BASH_PROFILE="$USER_HOME/.bash_profile"
    if ! grep -q "VSCODE_SKIP_KEYRING" "$BASH_PROFILE" 2>/dev/null; then
        sudo -u "$USERNAME" bash -c "cat >> '$BASH_PROFILE'" << 'EOF'

# bobide notification suppression - disable keyring completely
# NOTE: Redundant with wrapper script, but kept as backup
export VSCODE_SKIP_KEYRING=1
export ELECTRON_NO_ATTACH_CONSOLE=1
export GNOME_KEYRING_CONTROL=/dev/null
export PASSWORD_STORE_DIR=/dev/null
EOF
    fi
    
    # Disable gnome-keyring daemon for this user
    local AUTOSTART_DIR="$USER_HOME/.config/autostart"
    sudo -u "$USERNAME" mkdir -p "$AUTOSTART_DIR"
    
    # Create override file to disable gnome-keyring-daemon
    sudo -u "$USERNAME" bash -c "cat > '$AUTOSTART_DIR/gnome-keyring-pkcs11.desktop'" << 'EOF'
[Desktop Entry]
Type=Application
Name=Certificate and Key Storage
Hidden=true
EOF
    
    sudo -u "$USERNAME" bash -c "cat > '$AUTOSTART_DIR/gnome-keyring-secrets.desktop'" << 'EOF'
[Desktop Entry]
Type=Application
Name=Secret Storage Service
Hidden=true
EOF
    
    sudo -u "$USERNAME" bash -c "cat > '$AUTOSTART_DIR/gnome-keyring-ssh.desktop'" << 'EOF'
[Desktop Entry]
Type=Application
Name=SSH Key Agent
Hidden=true
EOF
    
    # Set proper ownership
    sudo chown -R "$USERNAME:$USERNAME" "$SETTINGS_DIR"
    
    # Create state file to mark bobide welcome screen as completed
    local STATE_DIR="$USER_HOME/.config/IBM Bob/User/globalStorage"
    sudo -u "$USERNAME" mkdir -p "$STATE_DIR"
    sudo -u "$USERNAME" bash -c "cat > '$STATE_DIR/storage.json'" << 'EOF'
{
    "workbench.welcomePage.walkthroughsCompleted": true,
    "workbench.welcomePage.walkthroughsShown": true
}
EOF
    
    # Create flag file to mark GNOME Initial Setup as completed
    local GNOME_INITIAL_SETUP_DIR="$USER_HOME/.config"
    sudo -u "$USERNAME" mkdir -p "$GNOME_INITIAL_SETUP_DIR"
    sudo -u "$USERNAME" touch "$GNOME_INITIAL_SETUP_DIR/gnome-initial-setup-done"
    echo "  ✓ Marked GNOME Initial Setup as completed"
    
    # Override system desktop file with modified version
    local DESKTOP_DIR="$USER_HOME/.local/share/applications"
    local DESKTOP_FILE="$DESKTOP_DIR/bobide.desktop"
    
    echo "  → Configuring desktop launcher..."
    sudo -u "$USERNAME" mkdir -p "$DESKTOP_DIR"
    
    # Copy system desktop file to user's directory
    sudo -u "$USERNAME" cp /usr/share/applications/bobide.desktop "$DESKTOP_FILE"
    
    # Modify the Exec lines to use wrapper and open agentic-lab
    sudo -u "$USERNAME" sed -i \
        -e "s|Exec=/usr/share/bobide/bobide %F|Exec=$BOBIDE_WRAPPER_PATH $USER_HOME/$LAB_NAME|g" \
        -e "s|Exec=/usr/share/bobide/bobide --new-window %F|Exec=$BOBIDE_WRAPPER_PATH --new-window $USER_HOME/$LAB_NAME|g" \
        "$DESKTOP_FILE"
    
    # Set proper permissions for desktop file (644, not executable)
    sudo chmod 644 "$DESKTOP_FILE"
    sudo chown "$USERNAME:$USERNAME" "$DESKTOP_FILE"
    
    # Update desktop database if available
    if command -v update-desktop-database &> /dev/null; then
        sudo -u "$USERNAME" update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    fi
    
    echo "  ✓ Desktop launcher configured (overriding system default)"
    
    # NOTE: Favorites bar is configured system-wide via dconf (see configure_system_dconf function)
    # Per-user dconf attempts here won't work because user isn't logged in yet
    
    echo "  ✓ bobide configuration complete for $USERNAME"
}









# ============================================
# Main
# ============================================
# Ensure dependencies exist
if ! command -v curl >/dev/null 2>&1; then
  sudo dnf install -y curl
fi

# if ! command -v unzip >/dev/null 2>&1; then
#   sudo dnf install -y unzip
# fi


# Check if bobide command already exists
if command -v bobide >/dev/null 2>&1; then
  echo "bobide command already exists, skipping RPM installation..."
else
  cd "$HOME"
  curl -fL -O "$BOBIDE_RPM_URL" || {
    echo "Failed to download package.zip"
    exit 1
  }

  echo "Installing RPMs..."
  sudo rpm -ivh "$HOME"/*.rpm || \
  sudo dnf install -y "$HOME"/*.rpm
fi

# Create the wrapper script (only needs to be done once, system-wide)
create_bobide_wrapper

# Configure system-wide dconf defaults (only needs to be done once)
configure_system_dconf


if [ -d "/home/itzuser/$LAB_NAME" ]; then
    echo "$LAB_NAME directory already exists for itzuser, skipping download..."
  else
# download lab contents
    echo "Downloading $LAB_NAME..."
    git clone -b "$LAB_BRANCH" --depth 1 --filter=blob:none --sparse "$LAB_REPO" "$LAB_NAME"
    cd $LAB_NAME
    git sparse-checkout set "$LAB_NAME"

    # Move contents up one level
    shopt -s dotglob
    mv $LAB_NAME/* .
    rm -rf $LAB_NAME
    rm -rf install.sh

    echo "Running system dependencies script..."
    chmod +x "$HOME/$LAB_NAME/install-system-deps.sh"
    yes | sudo "$HOME/$LAB_NAME/install-system-deps.sh"
fi

# Create users with configured range
echo "Creating users..."
for i in $(seq -w $USER_RANGE_START $USER_RANGE_END); do
  USERNAME="${USER_PREFIX}$(printf '%02d' $i)"
  if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists, skipping..."
  else
    sudo useradd -m "$USERNAME"
    echo "$USERNAME:$USER_PASSWORD" | sudo chpasswd
    echo "Created user: $USERNAME"

  fi

  # Check if lab directory already exists in user's home
  if [ -d "/home/$USERNAME/$LAB_NAME" ]; then
    echo "$LAB_NAME directory already exists for $USERNAME, skipping copy..."
  else
    echo "Copying $LAB_NAME to $USERNAME's home directory..."
    sudo cp -r /home/itzuser/$LAB_NAME /home/$USERNAME/
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/$LAB_NAME
    sudo chmod -R 755 /home/$USERNAME
    
    echo "Running user setup script..."
    chmod +x "$HOME/$LAB_NAME/user-setup.sh"
    sudo "$HOME/$LAB_NAME/user-setup.sh"


  fi
  
  # Configure bobide notifications for this user
  configure_bobide_notifications "$USERNAME"
  
done

echo ""
echo "✅ Installation complete!"
echo "✅ bobide notifications suppressed for all users"
echo ""
