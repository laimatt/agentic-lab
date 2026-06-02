#!/bin/bash

################################################################################
# Bobverse System Dependencies Installation Script for Linux
# 
# This script installs all required system dependencies for the Bobverse project:
# - Python 3.12 (or 3.10-3.13)
# - Node.js LTS (14+)
# - Build tools (make, bc, git)
#
# Supports: Ubuntu/Debian, Fedora/RHEL/CentOS, Arch Linux, openSUSE
#
# Usage: sudo ./install-system-deps.sh [OPTIONS]
################################################################################

set -e  # Exit on error

# Script version
VERSION="1.0.0"

# Required versions
REQUIRED_PYTHON_MAJOR=3
REQUIRED_PYTHON_MINOR_MIN=10
REQUIRED_PYTHON_MINOR_MAX=13
PREFERRED_PYTHON_VERSION="3.12"
REQUIRED_NODE_MAJOR=14

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Flags
DRY_RUN=false
VERBOSE=false
NON_INTERACTIVE=false
SKIP_PYTHON=false
SKIP_NODEJS=false
FORCE_INSTALL=false

################################################################################
# Helper Functions
################################################################################

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}===${NC} $1 ${CYAN}===${NC}\n"
}

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1"
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        print_verbose "Detected distribution: $DISTRO $DISTRO_VERSION"
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

get_python_version() {
    # Check for python3.12 first (preferred), then python3.11, 3.10, 3.13, then fallback to python3
    for py_cmd in python3.12 python3.13 python3.11 python3.10 python3; do
        if check_command "$py_cmd"; then
            local version=$($py_cmd --version 2>&1 | awk '{print $2}')
            local major=$(echo "$version" | cut -d. -f1)
            local minor=$(echo "$version" | cut -d. -f2)
            
            # Return version if it meets requirements
            if [ "$major" -eq "$REQUIRED_PYTHON_MAJOR" ] && \
               [ "$minor" -ge "$REQUIRED_PYTHON_MINOR_MIN" ] && \
               [ "$minor" -le "$REQUIRED_PYTHON_MINOR_MAX" ]; then
                echo "$version"
                return 0
            fi
        fi
    done
    echo "0.0.0"
}

check_python_version() {
    local version=$(get_python_version)
    if [ "$version" = "0.0.0" ]; then
        return 1
    fi
    
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    
    if [ "$major" -eq "$REQUIRED_PYTHON_MAJOR" ] && \
       [ "$minor" -ge "$REQUIRED_PYTHON_MINOR_MIN" ] && \
       [ "$minor" -le "$REQUIRED_PYTHON_MINOR_MAX" ]; then
        return 0
    else
        return 1
    fi
}

get_node_version() {
    if check_command node; then
        node --version 2>&1 | sed 's/v//'
    else
        echo "0.0.0"
    fi
}

check_node_version() {
    local version=$(get_node_version)
    if [ "$version" = "0.0.0" ]; then
        return 1
    fi
    
    local major=$(echo "$version" | cut -d. -f1)
    
    if [ "$major" -ge "$REQUIRED_NODE_MAJOR" ]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Installation Functions
################################################################################

install_ubuntu_debian() {
    print_header "Installing dependencies for Ubuntu/Debian"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would update package lists"
        print_info "[DRY RUN] Would install: software-properties-common"
    else
        print_info "Updating package lists..."
        apt update -qq
        apt install -y software-properties-common
    fi
    
    # Install Python
    if [ "$SKIP_PYTHON" = false ]; then
        if check_python_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Python $(get_python_version) is already installed"
        else
            print_info "Installing Python $PREFERRED_PYTHON_VERSION..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would add deadsnakes PPA"
                print_info "[DRY RUN] Would install: python$PREFERRED_PYTHON_VERSION python$PREFERRED_PYTHON_VERSION-venv python$PREFERRED_PYTHON_VERSION-dev"
            else
                add-apt-repository -y ppa:deadsnakes/ppa
                apt update -qq
                apt install -y \
                    python$PREFERRED_PYTHON_VERSION \
                    python$PREFERRED_PYTHON_VERSION-venv \
                    python$PREFERRED_PYTHON_VERSION-dev \
                    python3-pip
                print_success "Python $PREFERRED_PYTHON_VERSION installed"
            fi
        fi
    fi
    
    # Install Node.js
    if [ "$SKIP_NODEJS" = false ]; then
        if check_node_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Node.js $(get_node_version) is already installed"
        else
            print_info "Installing Node.js LTS..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would download and run NodeSource setup script"
                print_info "[DRY RUN] Would install: nodejs"
            else
                curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
                apt install -y nodejs
                print_success "Node.js $(get_node_version) installed"
            fi
        fi
    fi
    
    # Install build tools
    print_info "Installing build tools..."
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would install: make bc git build-essential curl"
    else
        apt install -y make bc git build-essential curl
        print_success "Build tools installed"
    fi
}

install_fedora_rhel() {
    print_header "Installing dependencies for Fedora/RHEL/CentOS"
    
    local PKG_MGR="dnf"
    if ! check_command dnf; then
        PKG_MGR="yum"
    fi
    
    # Install Python
    if [ "$SKIP_PYTHON" = false ]; then
        if check_python_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Python $(get_python_version) is already installed"
        else
            print_info "Installing Python $PREFERRED_PYTHON_VERSION..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would install: python$PREFERRED_PYTHON_VERSION python$PREFERRED_PYTHON_VERSION-devel"
            else
                $PKG_MGR install -y python$PREFERRED_PYTHON_VERSION python$PREFERRED_PYTHON_VERSION-devel
                print_success "Python $PREFERRED_PYTHON_VERSION installed"
            fi
        fi
    fi
    
    # Install Node.js
    if [ "$SKIP_NODEJS" = false ]; then
        if check_node_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Node.js $(get_node_version) is already installed"
        else
            print_info "Installing Node.js LTS..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would install: nodejs"
            else
                $PKG_MGR module install -y nodejs:lts || $PKG_MGR install -y nodejs
                print_success "Node.js $(get_node_version) installed"
            fi
        fi
    fi
    
    # Install build tools
    print_info "Installing build tools..."
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would install: make bc git gcc gcc-c++ curl"
    else
        $PKG_MGR install -y make bc git gcc gcc-c++ curl
        print_success "Build tools installed"
    fi
    
    # Check and upgrade SQLite if needed
    print_info "Checking SQLite version..."
    local sqlite_version=$(python3.12 -c "import sqlite3; print(sqlite3.sqlite_version)" 2>/dev/null || echo "0.0.0")
    local sqlite_major=$(echo "$sqlite_version" | cut -d. -f1)
    local sqlite_minor=$(echo "$sqlite_version" | cut -d. -f2)
    
    if [ "$sqlite_major" -lt 3 ] || ([ "$sqlite_major" -eq 3 ] && [ "$sqlite_minor" -lt 35 ]); then
        print_warning "SQLite $sqlite_version detected (need 3.35+). Compiling SQLite 3.45.1 from source..."
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY RUN] Would compile and install SQLite 3.45.1 from source"
        else
            # Install development tools needed for compilation
            $PKG_MGR install -y wget tar
            
            # Download and compile SQLite
            cd /tmp
            SQLITE_VERSION="3450100"
            SQLITE_YEAR="2024"
            
            print_info "Downloading SQLite 3.45.1..."
            wget -q https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
            
            if [ $? -eq 0 ]; then
                print_info "Extracting and compiling SQLite..."
                tar xzf sqlite-autoconf-${SQLITE_VERSION}.tar.gz
                cd sqlite-autoconf-${SQLITE_VERSION}
                
                ./configure --prefix=/usr/local
                make -j$(nproc)
                make install
                
                # Update library cache
                echo "/usr/local/lib" > /etc/ld.so.conf.d/sqlite3.conf
                ldconfig
                
                # Verify installation
                local new_version=$(python3.12 -c "import sqlite3; print(sqlite3.sqlite_version)" 2>/dev/null || echo "0.0.0")
                
                # Clean up
                cd /tmp
                rm -rf sqlite-autoconf-${SQLITE_VERSION} sqlite-autoconf-${SQLITE_VERSION}.tar.gz
                
                if [ "$new_version" != "0.0.0" ]; then
                    print_success "SQLite upgraded to version $new_version"
                else
                    print_warning "SQLite compiled but Python may need to be reinstalled to use new version"
                    print_info "Run: $PKG_MGR reinstall -y python$PREFERRED_PYTHON_VERSION"
                fi
            else
                print_error "Failed to download SQLite source"
                print_info "You may need to upgrade SQLite manually"
            fi
        fi
    else
        print_success "SQLite $sqlite_version is compatible (3.35+ required)"
    fi
}

install_arch() {
    print_header "Installing dependencies for Arch Linux"
    
    # Update package database
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would update package database"
    else
        print_info "Updating package database..."
        pacman -Sy --noconfirm
    fi
    
    # Install Python
    if [ "$SKIP_PYTHON" = false ]; then
        if check_python_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Python $(get_python_version) is already installed"
        else
            print_info "Installing Python..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would install: python python-pip"
            else
                pacman -S --noconfirm python python-pip
                print_success "Python $(get_python_version) installed"
            fi
        fi
    fi
    
    # Install Node.js
    if [ "$SKIP_NODEJS" = false ]; then
        if check_node_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Node.js $(get_node_version) is already installed"
        else
            print_info "Installing Node.js..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would install: nodejs npm"
            else
                pacman -S --noconfirm nodejs npm
                print_success "Node.js $(get_node_version) installed"
            fi
        fi
    fi
    
    # Install build tools
    print_info "Installing build tools..."
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would install: make bc git base-devel curl"
    else
        pacman -S --noconfirm make bc git base-devel curl
        print_success "Build tools installed"
    fi
}

install_opensuse() {
    print_header "Installing dependencies for openSUSE"
    
    # Install Python
    if [ "$SKIP_PYTHON" = false ]; then
        if check_python_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Python $(get_python_version) is already installed"
        else
            print_info "Installing Python $PREFERRED_PYTHON_VERSION..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would install: python312 python312-devel"
            else
                zypper install -y python312 python312-devel python312-pip
                print_success "Python $PREFERRED_PYTHON_VERSION installed"
            fi
        fi
    fi
    
    # Install Node.js
    if [ "$SKIP_NODEJS" = false ]; then
        if check_node_version && [ "$FORCE_INSTALL" = false ]; then
            print_success "Node.js $(get_node_version) is already installed"
        else
            print_info "Installing Node.js..."
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY RUN] Would install: nodejs npm"
            else
                zypper install -y nodejs npm
                print_success "Node.js $(get_node_version) installed"
            fi
        fi
    fi
    
    # Install build tools
    print_info "Installing build tools..."
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would install: make bc git gcc gcc-c++ curl"
    else
        zypper install -y make bc git gcc gcc-c++ curl
        print_success "Build tools installed"
    fi
}

################################################################################
# Verification Functions
################################################################################

verify_installations() {
    print_header "Verifying Installations"
    
    local all_ok=true
    
    # Verify Python
    if [ "$SKIP_PYTHON" = false ]; then
        if check_python_version; then
            print_success "Python $(get_python_version) - OK"
        else
            print_error "Python installation failed or version not supported"
            all_ok=false
        fi
    fi
    
    # Verify Node.js
    if [ "$SKIP_NODEJS" = false ]; then
        if check_node_version; then
            print_success "Node.js $(get_node_version) - OK"
            if check_command npm; then
                print_success "npm $(npm --version) - OK"
            else
                print_error "npm not found"
                all_ok=false
            fi
        else
            print_error "Node.js installation failed or version not supported"
            all_ok=false
        fi
    fi
    
    # Verify build tools
    for tool in make bc git; do
        if check_command "$tool"; then
            print_success "$tool - OK"
        else
            print_error "$tool not found"
            all_ok=false
        fi
    done
    
    if [ "$all_ok" = true ]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Help Function
################################################################################

show_help() {
    cat << EOF
Bobverse System Dependencies Installation Script v${VERSION}

This script installs all required system dependencies for the Bobverse project.

Usage: sudo ./install-system-deps.sh [OPTIONS]

Options:
  --dry-run           Show what would be installed without installing
  --verbose           Show detailed output
  --non-interactive   Run without user prompts (for CI/CD)
  --skip-python       Skip Python installation
  --skip-nodejs       Skip Node.js installation
  --force             Force reinstall even if already installed
  --help              Show this help message

Requirements:
  - Python: 3.10, 3.11, 3.12, or 3.13 (recommended: 3.12)
  - Node.js: 14+ (LTS recommended)
  - Build tools: make, bc, git

Supported Distributions:
  - Ubuntu/Debian
  - Fedora/RHEL/CentOS
  - Arch Linux
  - openSUSE

Examples:
  # Basic installation
  sudo ./install-system-deps.sh

  # Dry run to see what would be installed
  sudo ./install-system-deps.sh --dry-run

  # Verbose output for debugging
  sudo ./install-system-deps.sh --verbose

  # Skip Python installation (if already installed)
  sudo ./install-system-deps.sh --skip-python

  # Force reinstall all dependencies
  sudo ./install-system-deps.sh --force

After installation, run:
  make setup      # Install Python and npm dependencies
  make init-db    # Initialize database
  make start      # Start the application

EOF
}

################################################################################
# Main Function
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --skip-python)
                SKIP_PYTHON=true
                shift
                ;;
            --skip-nodejs)
                SKIP_NODEJS=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Print header
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Bobverse System Dependencies Installation Script       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Check root privileges
    check_root
    
    # Detect distribution
    detect_distro
    print_info "Distribution: $DISTRO $DISTRO_VERSION"
    
    # Check existing installations
    print_header "Checking Existing Installations"
    
    if check_python_version; then
        print_success "Python $(get_python_version) is installed"
    else
        print_warning "Python is not installed or version not supported"
    fi
    
    if check_node_version; then
        print_success "Node.js $(get_node_version) is installed"
    else
        print_warning "Node.js is not installed or version not supported"
    fi
    
    for tool in make bc git; do
        if check_command "$tool"; then
            print_success "$tool is installed"
        else
            print_warning "$tool is not installed"
        fi
    done
    
    # Confirm installation
    if [ "$NON_INTERACTIVE" = false ] && [ "$DRY_RUN" = false ]; then
        echo ""
        read -p "Continue with installation? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Install based on distribution
    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            install_ubuntu_debian
            ;;
        fedora|rhel|centos|rocky|almalinux)
            install_fedora_rhel
            ;;
        arch|manjaro|endeavouros)
            install_arch
            ;;
        opensuse*|sles)
            install_opensuse
            ;;
        *)
            print_error "Unsupported distribution: $DISTRO"
            print_info "Please install dependencies manually:"
            print_info "  - Python 3.10-3.13 (recommended: 3.12)"
            print_info "  - Node.js 14+ (LTS recommended)"
            print_info "  - Build tools: make, bc, git"
            exit 1
            ;;
    esac
    
    # Verify installations
    if [ "$DRY_RUN" = false ]; then
        if verify_installations; then
            print_header "Installation Complete!"
            print_success "All dependencies installed successfully"
            echo ""
            print_info "Next steps:"
            echo "  1. Run 'make setup' to install Python and npm dependencies"
            echo "  2. Run 'make init-db' to initialize the database"
            echo "  3. Run 'make start' to start the application"
            echo ""
        else
            print_error "Some installations failed. Please check the output above."
            exit 1
        fi
    else
        print_header "Dry Run Complete"
        print_info "No changes were made. Run without --dry-run to install."
    fi
}

# Run main function
main "$@"

# Made with Bob
