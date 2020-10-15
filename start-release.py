#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import tempfile
import time


ALLOWED_ENVIRONMENTS = ["dev", "prod"]
ALLOWED_CHANNELS = ["nightly", "beta", "stable"]

# Environment variables to set in the CodeBuild runner if they're present in
# the local system too.
FORWARD_ENVIRONMENT_VARIABLES = [
    "PROMOTE_RELEASE_ALLOW_MULTIPLE_TODAY",
]


def main(env, channel, override_commit):
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
    if override_commit is not None:
        vars["PROMOTE_RELEASE_OVERRIDE_COMMIT"] = override_commit
    for key, value in os.environ.items():
        if key in FORWARD_ENVIRONMENT_VARIABLES:
            vars[key] = value

    res = subprocess.run([
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
    ], stdout=subprocess.PIPE, check=True)
    build = json.loads(res.stdout)["build"]
    print(f"Build started with ID '{build['id']}'")

    build = {"id": "promote-release--dev:1dacf12e-1919-4ed6-9dfb-e357749eac6d", "logs": {}}

    # If the CloudWatch stream was not created yet poll the API
    while "streamName" not in build["logs"]:
        time.sleep(1)

        res = subprocess.run([
            "aws", "codebuild", "batch-get-builds",
            "--ids", build["id"],
        ], stdout=subprocess.PIPE, check=True)
        build = json.loads(res.stdout)["builds"][0]

    print()
    print("Logs available at:", build['logs']['deepLink'])
    print("You can also follow the logs on the terminal:")
    print()
    print(f"    aws logs tail --follow {build['logs']['groupName']}")
    print()


if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 4:
        print("usage: ./start-release.py <environment> <channel> [override-commit]")
        print()
        print("examples:")
        print("  ./start-release.py dev nightly")
        print("  ./start-release.py prod stable")
        exit(1)

    env = sys.argv[1]
    channel = sys.argv[2]
    override_commit = None
    if len(sys.argv) == 4:
        override_commit = sys.argv[3]

    main(env, channel, override_commit)
