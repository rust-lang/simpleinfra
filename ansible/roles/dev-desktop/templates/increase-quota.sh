#!/usr/bin/env bash

# {{ ansible_managed }}

# Set file system quota for all dev-desktop users
#
# This script can be used to update the file system quota for all dev-desktop
# users. It accepts three arguments:
#
#   -s <size>  Set the soft limit to <size> (e.g. 10G)
#   -h <size>  Set the hard limit to <size> (e.g. 10G)
#   --dry-run  Don't actually change anything, just print what would be done
#
# The sizes are mandatory, while --dry-run is optional.

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Arguments
dry_run=false
hard_limit=
soft_limit=

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--hard-limit)
      hard_limit="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--soft-limit)
      soft_limit="$2"
      shift # past argument
      shift # past value
      ;;
    --dry-run)
      dry_run=true
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      echo "Unexpected positional argument $1"
      exit 1
      ;;
  esac
done

# Validate input
limit_regex="[0-9]*G"

if [[ -z "${hard_limit}" ]]; then
  echo "Missing hard limit"
  exit 2
fi

if ! [[ "${hard_limit}" =~ $limit_regex ]]; then
  echo "Invalid hard limit: ${hard_limit}. Example: 50G"
  exit 2
fi

if [[ -z "${soft_limit}" ]]; then
  echo "Missing soft limit"
  exit 2
fi

if ! [[ "${soft_limit}" =~ $limit_regex ]]; then
  echo "Invalid soft limit: ${soft_limit}. Example: 50G"
  exit 2
fi

# Get list of users
users=$(cut -d: -f1 /etc/passwd | grep gh-)

# Set quota
for user in $users; do
  cmd="setquota -u ${user} ${soft_limit} ${hard_limit} 0 0 /"

  if [[ $dry_run = true ]]; then
    echo "${cmd}"
  else
    echo "Setting quota for user ${user} to ${soft_limit}/${hard_limit}"
    eval $cmd
  fi
done
