# System Dependencies Installation Script Plan

## Overview
Create a comprehensive Linux installation script (`install-system-deps.sh`) that automatically installs all system dependencies required for the Bobverse project.

## System Requirements Analysis

### Backend Dependencies (Python)
- **Python**: 3.10, 3.11, 3.12, or 3.13 (recommended: 3.12.0)
- **Python packages**: Managed via `pip` from [`requirements.txt`](requirements.txt:1)
- **System tools**: `python3-venv`, `python3-pip`

### Frontend Dependencies (Node.js)
- **Node.js**: Version 14+ (LTS recommended)
- **npm**: Comes with Node.js
- **Frontend packages**: Managed via `npm` from [`frontend/package.json`](frontend/package.json:1)

### Build Tools
- **make**: For running Makefile targets
- **bc**: Calculator for version comparison in Makefile
- **git**: Version control (likely already installed)
- **curl/wget**: For downloading installers

### Database
- **SQLite**: Built into Python's standard library (no separate installation needed)

## Script Architecture

### 1. Detection Phase
```bash
# Detect Linux distribution
- Ubuntu/Debian (apt)
- Fedora/RHEL/CentOS (dnf/yum)
- Arch Linux (pacman)
- openSUSE (zypper)
```

### 2. Verification Phase
```bash
# Check if dependencies are already installed
- Python 3.10-3.13
- Node.js 14+
- make
- bc
- git
```

### 3. Installation Phase
```bash
# Install missing dependencies based on distribution
- Update package manager
- Install Python 3.12 (if not present)
- Install Node.js LTS (if not present)
- Install build tools (make, bc, git)
```

### 4. Validation Phase
```bash
# Verify installations
- Check Python version
- Check Node.js version
- Check npm version
- Display summary
```

## Script Features

### User Experience
- **Color-coded output**: Success (green), warnings (yellow), errors (red)
- **Progress indicators**: Show what's being installed
- **Dry-run mode**: Option to see what would be installed without actually installing
- **Verbose mode**: Detailed output for debugging
- **Non-interactive mode**: For CI/CD environments

### Safety Features
- **Root check**: Require sudo/root privileges
- **Backup existing installations**: Don't overwrite working setups
- **Rollback capability**: Ability to undo changes if something fails
- **Dependency verification**: Confirm each installation succeeded

### Platform-Specific Handling

#### Ubuntu/Debian (apt)
```bash
# Add deadsnakes PPA for Python 3.12
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Install Python 3.12
sudo apt install -y python3.12 python3.12-venv python3.12-dev

# Install Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install build tools
sudo apt install -y make bc git build-essential
```

#### Fedora/RHEL/CentOS (dnf/yum)
```bash
# Install Python 3.12
sudo dnf install -y python3.12 python3.12-devel

# Install Node.js
sudo dnf module install -y nodejs:lts

# Install build tools
sudo dnf install -y make bc git gcc gcc-c++
```

#### Arch Linux (pacman)
```bash
# Install Python 3.12
sudo pacman -S --noconfirm python

# Install Node.js
sudo pacman -S --noconfirm nodejs npm

# Install build tools
sudo pacman -S --noconfirm make bc git base-devel
```

## Script Structure

```bash
#!/bin/bash

# 1. Configuration
VERSION="1.0.0"
REQUIRED_PYTHON_VERSION="3.12"
REQUIRED_NODE_VERSION="14"

# 2. Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 3. Helper functions
print_success() { ... }
print_error() { ... }
print_warning() { ... }
print_info() { ... }
check_root() { ... }
detect_distro() { ... }
check_command() { ... }
check_python_version() { ... }
check_node_version() { ... }

# 4. Installation functions
install_ubuntu_debian() { ... }
install_fedora_rhel() { ... }
install_arch() { ... }
install_opensuse() { ... }

# 5. Verification functions
verify_python() { ... }
verify_nodejs() { ... }
verify_build_tools() { ... }

# 6. Main execution
main() {
    # Parse arguments
    # Check root privileges
    # Detect distribution
    # Check existing installations
    # Install missing dependencies
    # Verify installations
    # Display summary
}

main "$@"
```

## Usage Examples

```bash
# Basic installation
sudo ./install-system-deps.sh

# Dry run (see what would be installed)
sudo ./install-system-deps.sh --dry-run

# Verbose output
sudo ./install-system-deps.sh --verbose

# Skip specific components
sudo ./install-system-deps.sh --skip-python
sudo ./install-system-deps.sh --skip-nodejs

# Force reinstall
sudo ./install-system-deps.sh --force

# Non-interactive mode (for CI/CD)
sudo ./install-system-deps.sh --non-interactive
```

## Integration with Existing Workflow

### Update Makefile
Add a new target to the [`Makefile`](Makefile:1):

```makefile
# Install system dependencies (requires sudo)
install-system-deps:
	@echo "Installing system dependencies..."
	@if [ ! -f install-system-deps.sh ]; then \
		echo "Error: install-system-deps.sh not found"; \
		exit 1; \
	fi
	@chmod +x install-system-deps.sh
	@sudo ./install-system-deps.sh
```

### Update README.md
Add installation instructions to [`README.md`](README.md:1):

```markdown
## 🚀 Quick Start (First Time Setup)

### 1. Install System Dependencies

```bash
# Make the script executable
chmod +x install-system-deps.sh

# Run the installation script (requires sudo)
sudo ./install-system-deps.sh
```

Or use the Makefile target:

```bash
make install-system-deps
```

### 2. Setup Project

```bash
make setup      # Install Python and npm dependencies
make init-db    # Initialize database
make start      # Start the application
```
```

## Error Handling

### Common Issues and Solutions

1. **Python version conflict**
   - Detect existing Python installations
   - Offer to install alongside existing versions
   - Update alternatives system

2. **Node.js version mismatch**
   - Use nvm (Node Version Manager) as fallback
   - Provide instructions for manual installation

3. **Permission errors**
   - Check for sudo/root access
   - Provide clear error messages

4. **Package manager failures**
   - Retry with exponential backoff
   - Suggest manual installation steps

## Testing Strategy

### Test Scenarios
1. Fresh Ubuntu 22.04 installation
2. Fresh Ubuntu 24.04 installation
3. Fedora 39/40
4. Arch Linux (latest)
5. System with existing Python 3.11
6. System with existing Node.js 16
7. System with all dependencies already installed

### Validation Checks
- Script exits with code 0 on success
- All required commands are available after installation
- Versions meet minimum requirements
- No conflicts with existing installations

## Documentation

### Script Comments
- Clear section headers
- Explanation of complex logic
- References to external documentation

### Help Output
```bash
./install-system-deps.sh --help

Bobverse System Dependencies Installation Script

Usage: install-system-deps.sh [OPTIONS]

Options:
  --dry-run           Show what would be installed without installing
  --verbose           Show detailed output
  --non-interactive   Run without user prompts (for CI/CD)
  --skip-python       Skip Python installation
  --skip-nodejs       Skip Node.js installation
  --force             Force reinstall even if already installed
  --help              Show this help message

Examples:
  sudo ./install-system-deps.sh
  sudo ./install-system-deps.sh --dry-run
  sudo ./install-system-deps.sh --verbose --skip-python
```

## Next Steps

1. **Review this plan** - Confirm the approach and features
2. **Switch to Code mode** - Implement the script
3. **Test the script** - Verify on different Linux distributions
4. **Update documentation** - Add usage instructions to README.md
5. **Add to Makefile** - Create convenient make target

## Implementation Checklist

- [ ] Create `install-system-deps.sh` with proper shebang
- [ ] Add color-coded output functions
- [ ] Implement distribution detection
- [ ] Add version checking functions
- [ ] Implement Ubuntu/Debian installation
- [ ] Implement Fedora/RHEL installation
- [ ] Implement Arch Linux installation
- [ ] Add verification functions
- [ ] Implement command-line argument parsing
- [ ] Add error handling and rollback
- [ ] Create comprehensive help text
- [ ] Make script executable
- [ ] Test on multiple distributions
- [ ] Update Makefile with new target
- [ ] Update README.md with instructions