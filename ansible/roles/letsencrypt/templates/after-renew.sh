#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

BASE="/etc/ssl/letsencrypt/after-renew.d"

for file in $(ls "${BASE}"); do
    if [[ -x "${BASE}/${file}" ]]; then
        "${BASE}/${file}"
    fi
done
