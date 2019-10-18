#!/bin/bash
#
# {{ ansible_managed }}
#

set -euo pipefail
IFS=$'\n\t'

update_image() {
    container="$1"
    image="$2"

    old_id="$(docker images --format "{{ '{{.ID}}' }}" "${image}")"
    docker pull "${image}"
    new_id="$(docker images --format "{{ '{{.ID}}' }}" "${image}")"

    if [[ "${old_id}" != "${new_id}" ]] && [[ -z "${NO_CONTAINER_RESTART+x}" ]]; then
        echo "restarting container ${container}"
        sudo systemctl restart "container-${container}.service"
    fi
}

eval $(aws ecr get-login --no-include-email --region "{{ images.region }}")

{% for name, options in containers.items() %}
update_image "{{ name }}" "{{ options.image }}"
{% endfor %}
