#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import urllib.parse


# Default port to use when connecting to the PostgreSQL database
DEFAULT_PORT = 5432

# Hostname of the bastion instance
BASTION_HOST = "bastion.infra.rust-lang.org"


def main(instance, database):
    """CLI entrypoint of the program."""
    creds = fetch_connection_url(instance, database)

    # Log into the bastion and execute psql in it.
    eprint("logging into the bastion and executing psql on it...\n")
    exit(subprocess.run([
        "ssh",
        # Allow forwarding the PGPASSWORD environment variable:
        "-o", "SendEnv PGPASSWORD",
        # Prevent sharing this SSH session with other ones on the same system.
        # While connection sharing usually works fine, SSH options are only set
        # during the first connection: we need SendEnv to be configured for
        # this script to work, and with connection sharing we risk it not being
        # set by the initial connection.
        "-o", "ControlPath none",
        "-o", "ControlMaster no",
        # Allocate a TTY for the SSH session, enabling the interactive prompt:
        "-t",
        # Host to connect to:
        BASTION_HOST,
        # Command line arguments:
        "psql",
        "--host", creds.hostname,
        "--port", str(creds.port if creds.port is not None else DEFAULT_PORT),
        "--user", creds.username,
        creds.path.strip("/"),
    ], env={
        **os.environ,

        # Pass the PostgreSQL password through an environment variable instead
        # of a command line argument: since it's possible to see other users'
        # command line arguments on a shared system, that would leak the
        # database password.
        "PGPASSWORD": creds.password,
    }).returncode)


def fetch_connection_url(instance, database):
    """Fetch the connection URL from AWS SSM Parameter Store"""
    eprint("fetching database credentials from AWS SSM Parameter Store...")
    try:
        out = json.loads(run_command([
            "aws", "ssm", "get-parameter",
            "--with-decryption",
            "--name", f"/prod/rds/{instance}/connection-urls/{database}",
        ]).stdout)
    except subprocess.CalledProcessError as e:
        err(f"failed to retrieve database credentials: {e}")
    return urllib.parse.urlparse(out["Parameter"]["Value"])


###############
#  Utilities  #
###############


def eprint(*args, **kwargs):
    """Just like print(), but outputs on stderr."""
    print(*args, file=sys.stderr, **kwargs)


def err(*args, **kwargs):
    """Show the error message and exit with status 1."""
    eprint("error:", *args, **kwargs)
    exit(1)


def run_command(*args, **kwargs):
    """Run a CLI program capturing stdout. Raise an exception if it fails."""
    return subprocess.run(
        *args,
        stdout=subprocess.PIPE,
        check=True,
        **kwargs,
    )


####################
#  CLI Invocation  #
####################


if __name__ == "__main__":
    if len(sys.argv) != 3:
        eprint(f"usage: {sys.argv[0]} <rds-instance> <database>")
        exit(1)
    main(sys.argv[1], sys.argv[2])
