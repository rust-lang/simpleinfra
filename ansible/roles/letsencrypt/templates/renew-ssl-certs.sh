#!/bin/bash
#
# {{ ansible_managed }}
#
set -euo pipefail
IFS=$'\n\t'

# During the initial renew nginx will fail to run as the certificate is
# missing, so lego will have to serve port 80.
if [[ $# -eq 1 ]] && [[ $1 = "initial-renew" ]]; then
    renew_kind="--http.port=:80"
    action="run"
else
    renew_kind="--http.webroot=/var/run/acme-challenges"
    action="renew"
fi

{% if dummy_certs %}
# Use the local Pebble instance to get a dummy certificate
server="https://localhost:14000/dir"
# Use Pebble's CA to validate connections to it
export LEGO_CA_CERTIFICATES=/etc/pebble/certs/pebble.minica.pem
# Remove the account as Pebble doesn't persist it
rm -rf "/etc/ssl/letsencrypt/accounts/localhost_14000/{{ email }}"
{% else %}
server="https://acme-v02.api.letsencrypt.org/directory"
{% endif %}

lego --email "{{ email }}" \
    --server "${server}" \
    --accept-tos \
    --path /etc/ssl/letsencrypt \
    --http \
    ${renew_kind} \
    {% for domain in domains -%}
    -d "{{ domain }}" \
    {% endfor -%}
    ${action}

sudo /etc/ssl/letsencrypt/after-renew
