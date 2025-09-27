#!/usr/bin/env bash
# Download the latest version of the gha-vm binary and run it.

set -euo pipefail
IFS=$'\n\t'

IMAGES_SERVER="https://gha-self-hosted-images.infra.rust-lang.org"

temp="$(mktemp -d)"
case "$(uname -m)" in
    x86_64)
        target="x86_64-unknown-linux-gnu"
        ;;
    aarch64)
        target="aarch64-unknown-linux-gnu"
        ;;
    *)
        echo "unsupported target: $(uname -m)" >&2
        exit 1
        ;;
esac

echo "retrieving the latest commit..."
commit="$(curl -Lf "${IMAGES_SERVER}/latest")"

echo "retrieving the executor for commit ${commit} and target ${target}..."
curl -Lfo "${temp}/gha-vm" "${IMAGES_SERVER}/executor/${commit}/gha-vm-$(uname -m)-unknown-linux-gnu"

echo "giving control to the executor..."
chmod +x "${temp}/gha-vm"
exec "${temp}/gha-vm" $@
