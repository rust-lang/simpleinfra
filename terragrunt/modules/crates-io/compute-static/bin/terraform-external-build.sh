#!/usr/bin/env bash

# Build script used by Terraform to build the function when planning.
#
# This script is called by Terraform to build the function when a user runs
# `terraform plan`. This ensures that the function is always up-to-date, and
# prevents users from accidentally uploading a stale version of the WASM module.
#
# Terraform expects the script to output a valid JSON object.
#
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
project_path=$(cd "${script_path}" && cd ".." && pwd)
project_name="${project_path##*/}"

cd "${project_path}" && fastly compute build --metadata-disable &>/dev/null

# Return a valid JSON object that Terraform can consume
echo "{\"path\": \"./${project_name}/pkg/compute-static.tar.gz\"}"
