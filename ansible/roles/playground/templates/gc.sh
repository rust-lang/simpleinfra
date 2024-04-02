#!/bin/bash

#
# {{ ansible_managed }}
#

# {% raw %}

set -euv -o pipefail

# How long a container must be running to be killed.
# Number of seconds.
MAX_TIME=3600

now=$(date "+%s")
to_kill=()

readarray -t container_ids < <(docker ps --format '{{ .ID }}' --no-trunc)

while read -r id started_at; do
    started_at=$(date --date "${started_at}" "+%s")
    running_time=$((now - started_at))

    if [[ "${running_time}" -gt "${MAX_TIME}" ]]; then
        to_kill+=("${id}")
    fi
done < <(docker inspect "${container_ids[@]}" --format '{{ .ID }} {{ .State.StartedAt }}')

if [[ ${#to_kill[@]} -gt 0 ]]; then
    docker kill "${to_kill[@]}"
fi

# {% endraw %}
