#!/usr/bin/env bash

# {{ ansible_managed }}

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

repquota -s /
