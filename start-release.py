#!/usr/bin/env python3

import json
import subprocess
import sys
import tempfile

ALLOWED_ENVIRONMENTS = ["dev", "prod"]
ALLOWED_CHANNELS = ["nightly", "beta", "stable"]


def main(env, channel, override_branch):
    if env not in ALLOWED_ENVIRONMENTS:
        print(f"error: unknown environment: {env}")
        print(f"       available environments: {ALLOWED_ENVIRONMENTS}")
        exit(1)
    if channel not in ALLOWED_CHANNELS:
        print(f"error: unknown channel: {channel}")
        print(f"       allowed channels: {ALLOWED_CHANNELS}")
        exit(1)

    vars = {}
    vars["PROMOTE_RELEASE_CHANNEL"] = channel
    if override_branch is not None:
        vars["PROMOTE_RELEASE_OVERRIDE_BRANCH"] = override_branch

    subprocess.run([
        "aws", "codebuild", "start-build",
        "--project-name", f"promote-release--{env}",
        "--environment-variables-override", json.dumps([
            {
                "name": name,
                "value": value,
                "type": "PLAINTEXT",
            }
            for name, value in vars.items()
        ]),
    ], check=True)


if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 4:
        print("usage: ./start-release.py <environment> <channel> [override-branch]")
        print()
        print("examples:")
        print("  ./start-release.py dev nightly")
        print("  ./start-release.py prod stable")
        exit(1)

    env = sys.argv[1]
    channel = sys.argv[2]
    override_branch = None
    if len(sys.argv) == 4:
        override_branch = sys.argv[3]

    main(env, channel, override_branch)
