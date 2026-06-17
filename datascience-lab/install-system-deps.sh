#!/bin/bash

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}â $1${NC}"
}

print_error() {
    echo -e "${RED}â $1${NC}"
}

print_info() {
    echo -e "${YELLOW}â¹ $1${NC}"
}


check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

get_pip_version() {
    if check_command pip; then
        node --version 2>&1 | sed 's/v//'
    else
        echo "0.0.0"
    fi
}

check_pip_version() {
    local version=$(get_pip_version)
    if [ "$version" = "0.0.0" ]; then
        return 1
    fi
    
    local major=$(echo "$version" | cut -d. -f1)
    
}


# Install pip
if check_pip_version && [ "$FORCE_INSTALL" = false ]; then
    print_success "pip $(get_pip_version) is already installed"
else
    print_info "Installing python3-pip..."
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would download and run python3-pip setup script"
        print_info "[DRY RUN] Would install: python3-pip"
    else
        sudo dnf install python3-pip
        print_success "pip $(get_pip_version) installed"
    fi
fi


