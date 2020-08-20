#!/usr/bin/env python3
# Our databases are hosted with RDS on a private subnet, and are not reachable
# from the public internet. Instead, you have to connect to them through our
# bastion server, increasing the security of the data we store.
#
# Unfortunately Terraform's PostgreSQL provider doesn't support any kind of
# proxy or port forwarding, but it only allows direct connections. To work
# around the problem, we call this script from an "external" Terraform
# provider: this script then setups the port forwarding using SSH, and returns
# the local address and port for Terraform to connect to.
#
# This script only has one limitation: the "external" Terraform provider
# doesn't support calling a command to cleanup the resources once the Terraform
# command exits, so we're forced to leak the SSH connection. To work around
# that it's possible to configure a timeout, and the script will reuse existing
# connections whenever possible.

import json
import os
import random
import subprocess
import sys
import socket
from contextlib import closing

PORT_MIN = 50000
PORT_MAX = 60000
REQUIRED_KEYS = {"address", "cache-name", "bastion", "port", "timeout"}

def forward(query):
    if set(query.keys()) != REQUIRED_KEYS:
        raise RuntimeError(f"required query keys: {REQUIRED_KEYS}")
    address = query["address"]
    bastion = query["bastion"]
    remote_port = query["port"]
    timeout = query["timeout"]
    cache_name = query["cache-name"]

    # Support multiple caches if multiple RDS servers are managed.
    cache_file = os.path.join(
        os.path.dirname(__file__),
        f".forward-ports-cache-{cache_name}.json",
    )

    # Avoid spawning a new connection if an existing one is already active
    cache = None
    try:
        with open(cache_file) as f:
            cache = json.load(f)
    except FileNotFoundError:
        pass
    if cache is not None and is_cache_valid(cache):
        return cache

    # Start the port forwarding in the background.
    local_port = random.randint(PORT_MIN, PORT_MAX)
    res = subprocess.run(
        [
            "ssh",
            "-f",  # Daemonize as soon as the connection is made.
            # Report if setting up the forwarding failed:
            "-o", "ExitOnForwardFailure=yes",
            # Port forwarding:
            "-L", f"localhost:{local_port}:{address}:{remote_port}",
            # Server to connect to:
            bastion,
            # The SSH client stops the port forwarding as soon as command on the
            # remote server ends. Because of that we run "sleep" in the forwarding
            # to achieve the timeout:
            "sleep", str(timeout),
        ],
        check=True,

        # The SSH process never exits when its output is captured. This happens
        # both if we try to capture it in the process, *and* if we don't
        # capture it, since the Terraform External Provider captures the
        # output on its own anyway.
        #
        # If you don't want to spend an hour debugging this, please do not
        # change these arguments :)  -pietro
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL,
    )

    # Cache the result and then return it.
    payload = {
        "host": "localhost",
        "port": str(local_port),
    }
    with open(cache_file, "w") as f:
        json.dump(payload, f)
    return payload

def is_cache_valid(cache):
    # https://stackoverflow.com/a/35370008
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        return sock.connect_ex((cache["host"], int(cache["port"]))) == 0

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
    terraform_external_program_protocol(forward)
