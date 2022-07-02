#!/bin/bash
#
# {{ ansible_managed }}
#

set -euo pipefail
IFS=$'\n\t'

# See https://unix.stackexchange.com/questions/82598
# Copied from rust-lang/rust's CI
function retry {
  echo "Attempting with retry:" "$@"
  local n=1
  local max=5
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        sleep $n  # don't retry immediately
        ((n++))
        echo "Command failed. Attempt $n/$max:"
      else
        echo "The command has failed after $n attempts."
        return 1
      fi
    }
  done
}

update_image() {
    container="$1"
    image="$2"

    aws ecr get-login-password --region "{{ images.region }}" | docker login \
        --username AWS \
        --password-stdin \
        "$image"

    old_id="$(docker images --format "{{ '{{.ID}}' }}" "${image}")"
    retry docker pull "${image}"
    new_id="$(docker images --format "{{ '{{.ID}}' }}" "${image}")"

    if [[ "${old_id}" != "${new_id}" ]] && [[ -z "${NO_CONTAINER_RESTART+x}" ]]; then
        echo "restarting container ${container}"
        sudo systemctl restart "container-${container}.service"
    fi
}

{% for name, options in containers.items() %}
update_image "{{ name }}" "{{ options.image }}"
{% endfor %}
