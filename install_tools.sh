#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
    echo "error: 'sudo' is required to install packages" >&2
    exit 1
fi

echo "installing: iverilog gtkwave gh"
sudo apt-get update
sudo apt-get install -y iverilog gtkwave gh

echo "installation complete"

echo "versions:"
iverilog -V | head -n 1 || true
gtkwave --version | head -n 1 || true
gh --version | head -n 1 || true
