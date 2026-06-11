#!/bin/bash

# Java Modernization Lab - Environment Setup Script
# This script installs all prerequisites needed for the Java Modernization workflow

set -e  # Exit on any error

echo "=========================================="
echo "Java Modernization Lab - Environment Setup"
echo "=========================================="
echo ""

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

# Check if SDKMAN is installed
echo "Step 1: Checking for SDKMAN..."
if [ -d "$HOME/.sdkman" ]; then
    print_success "SDKMAN is already installed"
else
    print_info "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    print_success "SDKMAN installed successfully"
fi

# Source SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    print_success "SDKMAN initialized"
else
    print_error "Failed to initialize SDKMAN"
    exit 1
fi

echo ""
echo "Step 2: Installing Java 8..."
# Check if Java 8 is already installed
if sdk list java | grep -q "8.0.472-amzn" && sdk current java | grep -q "8.0.472-amzn"; then
    print_success "Java 8 (8.0.472-amzn) is already installed and set as default"
else
    print_info "Installing Java 8 (Amazon Corretto 8.0.472)..."
    sdk install java 8.0.472-amzn || print_info "Java 8 may already be installed"
    sdk default java 8.0.472-amzn
    print_success "Java 8 installed and set as default"
fi

echo ""
echo "Step 3: Installing Maven..."
# Check if Maven is already installed
if sdk list maven | grep -q "3.9.16" && sdk current maven | grep -q "3.9.16"; then
    print_success "Maven 3.9.16 is already installed and set as default"
else
    print_info "Installing Maven 3.9.16..."
    sdk install maven 3.9.16 || print_info "Maven 3.9.16 may already be installed"
    sdk default maven 3.9.16
    print_success "Maven 3.9.16 installed and set as default"
fi

echo ""
echo "Step 4: Verifying installations..."
# Verify Java installation
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    print_success "Java is available: $JAVA_VERSION"
else
    print_error "Java installation verification failed"
    exit 1
fi

# Verify Maven installation
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn --version | head -n 1)
    print_success "Maven is available: $MVN_VERSION"
else
    print_error "Maven installation verification failed"
    exit 1
fi

# echo ""
# echo "Step 5: Testing build (if pom.xml exists)..."
# if [ -f "pom.xml" ]; then
#     print_info "Running test build: mvn clean compile"
#     if mvn clean compile -q; then
#         print_success "Test build completed successfully"
#     else
#         print_error "Test build failed - please check the output above"
#         exit 1
#     fi
# else
#     print_info "No pom.xml found in current directory - skipping build test"
# fi

echo ""
echo "=========================================="
print_success "Environment setup completed successfully!"
echo "=========================================="
echo ""
echo "Summary of installed tools:"
echo "  - SDKMAN: $(sdk version | grep 'script:' | awk '{print $2}')"
echo "  - Java: $(java -version 2>&1 | head -n 1 | awk '{print $3}' | tr -d '"')"
echo "  - Maven: $(mvn --version | head -n 1 | awk '{print $3}')"
echo ""
echo "To use these tools in a new terminal session, run:"
echo "  source ~/.sdkman/bin/sdkman-init.sh"
echo ""
echo "Or add this line to your ~/.bashrc or ~/.zshrc:"
echo "  export SDKMAN_DIR=\"\$HOME/.sdkman\""
echo "  [[ -s \"\$SDKMAN_DIR/bin/sdkman-init.sh\" ]] && source \"\$SDKMAN_DIR/bin/sdkman-init.sh\""
echo ""

# Made with Bob
