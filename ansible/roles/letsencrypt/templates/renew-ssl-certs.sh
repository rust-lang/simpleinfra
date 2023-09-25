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

retries="{{ vars_ssl_renew_number_of_retries }}"
wait_time="{{ vars_ssl_renew_retry_delay }}"

lego_cmd="lego --email '{{ email }}' \
        --server '${server}' \
        --accept-tos \
        --path /etc/ssl/letsencrypt \
        --http \
        ${renew_kind} \
        {% for domain in domains -%}
        -d '{{ domain }}' \
        {% endfor -%}
        ${action}"

function run_with_retries {
    command=$1
    local i=0
    while true; do
        ${command}
        exit_code=$?

        if [ ${exit_code} -eq 0 ]; then
            break
        fi

        if [ ${i} -ge ${retries} ]; then
            exit ${exit_code}
        fi

        jitter=$(($RANDOM % 10))
        wait_time_with_jitter=$((${wait_time} + ${jitter}))

        echo "Command failed with exit code ${exit_code}. Retrying in ${wait_time_with_jitter} seconds..."
        sleep ${wait_time_with_jitter}

        i=$(($i + 1))
    done
}

set +e
run_with_retries $lego_cmd
set -e

sudo /etc/ssl/letsencrypt/after-renew
