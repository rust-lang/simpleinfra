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

# Internal mode used after dropping privileges to a home directory owner.
cleanup_home_path=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --cleanup-home)
      cleanup_home_path="${2}"
      shift # past argument
      shift # past value
      ;;
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

cleanup_home() {
  local home="${1}"
  local all_cache_directories
  local unused_cache_directories

  # This command combines (`-o`) two different conditions to find all build and
  # target directories that users have created. Within each home directory, we
  # recursively look for directories that either have a file named `x.py` and a
  # directory named `build`, or a file named `Cargo.toml` and a directory named
  # `target`.
  all_cache_directories=$(find "${home}" -type d \( -name build -execdir test -f "x.py" \; -o -name target -execdir test -f "Cargo.toml" \; \) -print | sort | uniq)

  # For each checkout, we want to determine if the user has been working on it
  # within the `$time` number of days.
  unused_cache_directories=$(for directory in $all_cache_directories; do
    project=$(dirname "${directory}")

    # Find all directories with files that have been modified less than $time days ago
    modified=$(find "${project}" -type f -mtime -"${time}" -printf '%h\n' | xargs -r dirname | sort | uniq)

    # If no files have been modified in the last `$time` days, then the project is
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
}

if [[ -n "${cleanup_home_path}" ]]; then
  # Ensure this mode isn't called with root privileges.
  if [[ "$(id -u)" -eq 0 ]]; then
    echo "Error: --cleanup-home must not be run as root." >&2
    exit 1
  fi

  # Ensure the caller only cleans their own home.
  if [[ "$(realpath "${cleanup_home_path}")" != "$(realpath "${HOME}")" ]]; then
    echo "Error: --cleanup-home may only target your own home directory." >&2
    exit 1
  fi

  cleanup_home "${cleanup_home_path}"
  exit 0
fi

# The cron job starts as root so it can enumerate /home.
# Iterate over home directories with null delimiters so unusual names are safe.
find /home -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' home; do
  # Get the owner of the home directory.
  uid=$(stat -c '%u' "${home}") || continue

  # Skip home directories owned by root.
  [[ "${uid}" -eq 0 ]] && continue

  # Prepare args to re-enter this script in single-home cleanup mode, preserving the age cutoff.
  args=(--cleanup-home "${home}" -t "${time}")

  # Keep dry-run behavior consistent when the root-level cron wrapper delegates.
  if [[ "${dry_run}" == true ]]; then
    args+=(--dry-run)
  fi

  # Execute this script with the `--cleanup-home` flag to clean up a single user's home directory
  # using their privileges.
  # Dropping privileges prevents deleting paths outside the user's home in case of malicious symlinks.
  # `-H` sets the HOME variable to target user's home dir.
  if ! sudo -H -u "#${uid}" -- "$0" "${args[@]}"; then
    echo "Warning: cleanup failed for ${home}; continuing with remaining homes." >&2
  fi
done
