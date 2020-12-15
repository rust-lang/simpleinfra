#!/bin/bash
#
# {{ ansible_managed }}
#

set -euo pipefail
IFS=$'\n\t'

SOURCE="/opt/gha-self-hosted/source"
ARCH="$(uname -m)"

for image in "$(ls "${SOURCE}/images")"; do
    dest="/opt/gha-self-hosted/rootfs/${image}.qcow2"
    if [[ "${BOOT_TIME-0}" = "1" ]] && [[ -f "${dest}" ]]; then
        echo "image ${image} already exists"
        continue
    fi
    echo "building image ${image}"

    cd "${SOURCE}/images/${image}"
    make
    mv "${SOURCE}/images/${image}/build/${ARCH}/rootfs.qcow2" "${dest}"
done

# Restart all the VMs
# This will *not* restart them if they're currently running a build!
{% for instance in instances %}
sudo systemctl reload gha-vm-{{ instance.name }}.service
{% endfor %}
