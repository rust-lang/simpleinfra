#!/usr/bin/env python3

import getpass
import json
import pathlib
import subprocess
import sys
import shlex

# Number of seconds after which the opened session will expire.
SESSION_DURATION = 43200  # 12 hours

# Creating a session requires the ARN of the MFA device used to authenticate,
# but with the current set of permissions obtaining that ARN requires two other
# API calls (one to get the name of the user, and one to get the list of MFA
# devices the user owns).
#
# Doing multiple API calls is not great if a team member uses a hardware token
# to authorize accesses to the long-term credentials: to avoid that, the ARN of
# the MFA device (which does not contain any secret data) is cached inside a
# plaintext file after first use.
MFA_CACHE_PATH = pathlib.Path(__file__).resolve().parent / ".aws-creds-mfa-arn"


def main():
    """CLI entrypoint of the program."""
    serial = cached(MFA_CACHE_PATH, lambda: load_mfa_device())
    eprint(f"using MFA device with serial ID {serial}")

    code = getpass.getpass("TOTP code: ")

    env = get_session_token(SESSION_DURATION, serial, code)
    dump_env_bash(env)


def get_session_token(duration, mfa_serial, mfa_code):
    """Call the STS API to fetch a set of credentials authorized with MFA."""
    eprint("obtaining a temporary session token...")
    try:
        out = json.loads(run_command([
            "aws", "sts", "get-session-token",
            "--duration-seconds", str(duration),
            "--serial-number", mfa_serial,
            "--token-code", mfa_code,
        ]).stdout)
    except subprocess.CalledProcessError as e:
        err(f"failed to get a session token: {e}")

    env = {}
    env["AWS_ACCESS_KEY_ID"] = out["Credentials"]["AccessKeyId"]
    env["AWS_SECRET_ACCESS_KEY"] = out["Credentials"]["SecretAccessKey"]
    env["AWS_SESSION_TOKEN"] = out["Credentials"]["SessionToken"]
    return env


def load_mfa_device():
    """Retrieve the single TOTP MFA device the user configured."""
    eprint("retrieving information about your account...")
    try:
        user_out = json.loads(run_command(["aws", "iam", "get-user"]).stdout)
    except subprocess.CalledProcessError as e:
        err(f"failed to get information about your account: {e}")

    eprint("retrieving the list of MFA devices on your account...")
    try:
        mfa_out = json.loads(run_command([
            "aws", "iam", "list-mfa-devices",
            "--user-name", user_out["User"]["UserName"],
        ]).stdout)
    except subprocess.CalledProcessError as e:
        err(f"failed to list MFA devices: {e}")

    serial = None
    for device in mfa_out["MFADevices"]:
        # Only TOTP devices are supported
        user = device["UserName"]
        if not device["SerialNumber"].endswith(f":mfa/{user}"):
            continue

        # Only a single TOTP device is supported
        if serial is None:
            serial = device["SerialNumber"]
        else:
            err("there are multiple TOTP devices on your account")

    if serial is None:
        err("there is no TOTP device on your account")

    return serial


def dump_env_bash(env):
    """Print environment variables to stdout, prepared for eval."""
    for key, value in env.items():
        value = shlex.quote(value)
        print(f"export {key}=\"{value}\"")


###############
#  Utilities  #
###############


def cached(path, get):
    """Store the result of the computation in a plaintext file."""
    if path.is_file():
        return path.read_text().strip()
    else:
        val = get()
        path.write_text(f"{val}\n")
        return val


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
