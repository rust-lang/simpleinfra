#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import urllib.parse
import argparse


# Default port to use when connecting to the PostgreSQL database
DEFAULT_PORT = 5432

# Hostname of the default bastion instance
DEFAULT_BASTION_HOST = "bastion.infra.rust-lang.org"

def main():
    """CLI entrypoint of the program."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i", "--instance", help="database instance to connect to", default=None,
    )
    parser.add_argument(
        "-d", "--database", help="database connect to", default=None,
    )
    parser.add_argument(
        "-k", "--ssm-key", help="the ssm key where the database url is stored", default=None,
    )
    parser.add_argument(
        "-b", "--bastion", help="the bastion host (optionally with the '$USERNAME@' prepended)", default=DEFAULT_BASTION_HOST,
    )
    args = parser.parse_args()
    creds = fetch_connection_url(get_key(args))

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
        args.bastion,
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

def get_key(args):
    if args.instance and args.database:
        return f"/prod/rds/{args.instance}/connection-urls/{args.database}"
    elif args.ssm_key:
        return args.ssm_key
    else:
        err("error: either both the instance (-i) and database (-d) must \
            be specified or the raw ssm parameter store key (-k) where the\
            database url is stored")


def fetch_connection_url(key):
    """Fetch the connection URL from AWS SSM Parameter Store"""
    eprint("fetching database credentials from AWS SSM Parameter Store...")
    try:
        out = json.loads(run_command([
            "aws", "ssm", "get-parameter",
            "--with-decryption",
            "--name", key,
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
    main()
