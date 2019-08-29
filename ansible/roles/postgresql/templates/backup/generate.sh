#!/bin/bash
set -euo pipefail

DATABASES="{% for db in databases.keys() %}{{ db }}{% endfor %}"
SAVE_TO="/tmp/postgresql-backups"

# Create the destination directory
rm -rf "${SAVE_TO}"
mkdir "${SAVE_TO}"

# Ensure no one can read the destination directory content
chmod 0700 "${SAVE_TO}"

# Dump all the databases
for db in ${DATABASES}; do
    pg_dump "${db}" | gzip > "${SAVE_TO}/${db}.sql.gz"
done
