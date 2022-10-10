#!/usr/bin/env bash

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Check if rustup is already installed and exit if that's the case.
if command -v rustup &>/dev/null; then
  rustup --version
  exit 0
fi

init_git.py

echo "Installing rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
