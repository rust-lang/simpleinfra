#!/usr/bin/env bash

#
# {{ ansible_managed }}
#

# Clean up unused checkouts
#
# This script is used to find old checkouts that are no longer in use. Given the
# size of the build directory, regularly cleaning them up can save significant
# amounts of disk space.

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Print directories and their size instead of deleting them
dry_run=false

# Default to search for checkouts older than 60 days
time="60"

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      dry_run=true
      shift # past argument
      ;;
    -t|--time)
      time="${2}"
      shift # past argument
      shift # past value
      ;;
    -*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Find all build or target directories created by users
#
# This command combines (`-o`) two different conditions to find all build and
# target directories that users have created. Within each home directory, we
# recursively look for directories that either have a file named `x.py` and a
# directory named `build`, or a file named `Cargo.toml` and a directory named
# `target`.
all_cache_directories=$(find /home -type d \( -name build -execdir test -f "x.py" \; -o -name target -execdir test -f "Cargo.toml" \; \) -print | sort | uniq)

# For each checkout, we want to determine if the user has been working on it
# within the `$time` number of days.
unused_cache_directories=$(for directory in $all_cache_directories; do
  project=$(dirname "${directory}")

  # Find all directories with files that have been modified less than $time days ago
  modified=$(find "${project}" -type f -mtime -"${time}" -printf '%h\n' | xargs -r dirname | sort | uniq)

  # If no files have been modified in the last 90 days, then the project is
  # considered old.
  if [[ -z "${modified}" ]]; then
    echo "${directory}"
  fi
done)

# Delete the build directories in the unused checkouts
for directory in $unused_cache_directories; do
  if [[ "${dry_run}" == true ]]; then
    du -sh "${directory}"
  else
    echo "Deleting ${directory}"
    rm -rf "${directory}"
  fi
done
