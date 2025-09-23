#!/usr/bin/env python3
# The "lambda" Terraform module needs to create a zip archive of the Lambda's
# source code, to upload it to AWS when the source changes.
#
# While Terraform has a native archive_file data source, it doesn't produce
# reproducible archives between operative systems. We hit this when two members
# of the infrastructure team (on macOS and Linux) tried to apply changes, and
# one member was prompted to replace the lambda uploaded by the other member,
# even though the source was the same.
#
# The issue is known upstream, but it's not fixed yet:
# https://github.com/terraform-providers/terraform-provider-archive/issues/48
#
# To work around the issue we're using a custom Python script with the
# "external" data source, which compresses the source code while producing a
# deterministic archive.

import base64
import hashlib
import json
import os
import sys
import zipfile

def pack(query):
    # Validate input parameters.
    if set(query.keys()) != {"source_dir", "destination"}:
        raise RuntimeError(
            "the query should only contain the 'source_dir' and 'destination' keys"
        )

    # Ensure the source directory exists and is not empty
    if not os.path.isdir(query["source_dir"]):
        print(f"source_dir absolute path: {os.path.abspath(query['source_dir'])}", file=sys.stderr)
        raise RuntimeError(f"source_dir does not exist or is not a directory: {query['source_dir']}")

    # First collect the list of paths to add to the archive, and sort them.
    paths = []
    for root, dirs, files in os.walk(query["source_dir"]):
        for name in files:
            paths.append(os.path.join(root, name))
    paths = list(sorted(paths))

    if len(paths) == 0:
        raise RuntimeError(f"source_dir contains no files to package: {query['source_dir']}")

    # Then add all of them to the destination archive.
    parent = os.path.dirname(query["destination"])
    if parent:
        os.makedirs(parent, exist_ok=True)
    zip = zipfile.ZipFile(query["destination"], mode="w")
    for path in paths:
        # Override the permissions to set 0644 if the file is not executable,
        # or 0755 if the file is executable.
        permission = 0o100644
        if os.access(path, os.X_OK):
            permission = 0o100755

        # Force the permissions and the modification date, to avoid different
        # outputs on different machines.
        info = zipfile.ZipInfo(os.path.relpath(path, query["source_dir"]))
        info.external_attr = permission << 16
        info.date_time = (1980, 1, 1, 0, 0, 0)

        zip.writestr(
            info,
            open(path, "rb").read(),
            compress_type=zipfile.ZIP_DEFLATED,
        )
    zip.close()

    # Finally calculate hashes, passed back later to Terraform.
    with open(query["destination"], "rb") as f:
        content = f.read()

        sha256_bin = hashlib.sha256(content).digest()
        base64sha256 = base64.b64encode(sha256_bin).decode("ascii")

    # This data will be returned by the Terraform data source.
    return {
        "path": query["destination"],
        "base64sha256": base64sha256,
    }

# This function implements Terraform's external program protocol, allowing the
# function provided as the argument to communicate with Terraform's "external"
# data source.
#
# Documentation on the protocol can be found at:
# https://www.terraform.io/docs/providers/external/data_source.html#external-program-protocol
def terraform_external_program_protocol(inner):
    input = json.load(sys.stdin)
    try:
        result = inner(input)
    except Exception as e:
        print(e.__class__.__name__ + ": " + str(e), file=sys.stderr)
        exit(1)

    print(json.dumps(result))
    exit(0)

if __name__ == "__main__":
    terraform_external_program_protocol(pack)
