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

    with tempfile.NamedTemporaryFile() as f:
        payload = {}
        payload["channel"] = channel
        if override_branch is not None:
            payload["branch"] = override_branch

        output = subprocess.run([
            "aws", "lambda", "invoke",
            "--function-name", f"promote-release--{env}",
            "--payload", json.dumps(payload),
            f.name
        ], check=True)
        res = json.load(f)

        if "errorMessage" in res:
            print(res["errorMessage"])
            if "stackTrace" in res:
                print("\nStack trace:")
                for line in res["stackTrace"]:
                    print(line, end="")
            exit(1)
        else:
            print(res["message"])


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
