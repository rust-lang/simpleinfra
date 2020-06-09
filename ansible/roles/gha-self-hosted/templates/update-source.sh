#!/bin/bash
#
# {{ ansible_managed }}
#

set -euo pipefail
IFS=$'\n\t'

cd /opt/gha-self-hosted/source
git pull

sudo systemctl start gha-self-hosted-rebuild-image.service
