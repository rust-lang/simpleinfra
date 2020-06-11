#!/bin/bash
#
# {{ ansible_managed }}
#

set -euo pipefail
IFS=$'\n\t'

cd /opt/gha-self-hosted/source

start_sha="$(git rev-parse HEAD)"
git pull
end_sha="$(git rev-parse HEAD)"

# If there were changes in the images/ directory between the two commits,
# rebuild the local images.
if git diff "${start_sha}..${end_sha}" --name-only | grep "^images/" >/dev/null; then
    sudo systemctl start gha-self-hosted-rebuild-image.service
fi
