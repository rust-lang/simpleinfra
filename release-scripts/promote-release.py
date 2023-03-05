#!/usr/bin/env python3

import argparse
import json
import subprocess
import time


ALLOWED_ACTIONS = ["release", "branches"]
ALLOWED_ENVIRONMENTS = ["dev", "prod"]
ALLOWED_CHANNELS = ["nightly", "beta", "stable"]


def promote_release(args):
    if args.env not in ALLOWED_ENVIRONMENTS:
        print(f"error: unknown environment: {args.env}")
        print(f"       available environments: {ALLOWED_ENVIRONMENTS}")
        exit(1)
    if args.channel not in ALLOWED_CHANNELS:
        print(f"error: unknown channel: {args.channel}")
        print(f"       allowed channels: {ALLOWED_CHANNELS}")
        exit(1)

    vars = {}
    vars["PROMOTE_RELEASE_ACTION"] = "promote-release"
    vars["PROMOTE_RELEASE_CHANNEL"] = args.channel
    if args.override_commit is not None:
        vars["PROMOTE_RELEASE_OVERRIDE_COMMIT"] = args.override_commit
    if args.bypass_startup_checks:
        vars["PROMOTE_RELEASE_BYPASS_STARTUP_CHECKS"] = "1"

    if args.env == "dev" and args.channel == "stable":
        if args.release_date:
            vars["PROMOTE_RELEASE_BLOG_REPOSITORY"] = "rust-lang/blog.rust-lang.org"
        if args.release_date is None and not args.bypass_startup_checks:
            print("--release_date YYYY-MM-DD required for stable dev-static releases")
            exit(1)
        if args.release_date:
            vars["PROMOTE_RELEASE_BLOG_SCHEDULED_RELEASE_DATE"] = args.release_date

    run_build(args.env, vars)


def promote_branches():
    vars = {}
    vars["PROMOTE_RELEASE_ACTION"] = "promote-branches"
    # Not actually used, but needed by the configuration parsing code. We set it
    # to nightly which is 'safer' to get wrong.
    vars["PROMOTE_RELEASE_CHANNEL"] = "nightly"
    run_build('prod', vars)


def run_build(env, vars):
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
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(help='release or branches',
                                       required=True, dest='action')
    parser_a = subparsers.add_parser('release', help='promote-release')
    parser_b = subparsers.add_parser('branches', help='promote-branches')

    parser_a.add_argument("env", help="The environment to run the release on")
    parser_a.add_argument("channel", help="The channel to release")
    parser_a.add_argument(
        "override_commit",
        help="The commit hash to release",
        nargs="?",
    )
    parser_a.add_argument(
        "--bypass-startup-checks",
        help="Bypass the checks that prevent unwanted releases",
        action="store_true",
        dest="bypass_startup_checks",
    )
    parser_a.add_argument(
        "--release-date",
        help="YYYY-MM-DD date of the real release, for blog post"
    )
    args = parser.parse_args()

    if args.action not in ALLOWED_ACTIONS:
        print(f"error: unknown channel: {args.action}")
        print(f"       allowed channels: {ALLOWED_ACTIONS}")
        exit(1)

    if args.action == "release":
        promote_release(args)
    elif args.action == "branches":
        promote_branches()
