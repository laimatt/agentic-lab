#!/bin/bash
USERNAME=$1
LAB_NAME=$2

if command -v uv &> /dev/null; then
    UV_VERSION=$(uv --version | head -n 1)
    print_success "uv is already available: $UV_VERSION"
else
    echo "installing uv"
    pip install uv
fi

uv venv
echo "virtual environment created"