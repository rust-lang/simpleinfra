#!/usr/bin/env python3

# We want to grant folks on the release team the ability to start publishing
# releases, but simply granting them permission to start the CodeBuild job
# grants way too many privileges. For example, it would allow them to bypass
# startup checks, override the commit being released, or worse override the
# command being executed by CodeBuild to exfiltrate secrets.
#
# To solve the problem, this script accepts a limited set of actions allowed to
# be executed, and invokes CodeBuild with the right environment variables. This
# means we can safely grant the release team access to this function.

import boto3
import time


codebuild = boto3.client("codebuild")


def handler(event, context):
    match event["action"]:
        case "update-rust-branches":
            # The channel for updating branches is not actually used by
            # promote-release, but we have to pass it anyway.
            return run_build("promote-branches", "prod", "nightly")

        case "publish-rust-dev-nightly":
            return run_build("promote-release", "dev", "nightly")

        case "publish-rust-dev-beta":
            return run_build("promote-release", "dev", "beta")

        case "publish-rust-dev-stable":
            return run_build(
                "promote-release",
                "dev",
                "stable",
                {
                    "PROMOTE_RELEASE_BLOG_REPOSITORY": "rust-lang/blog.rust-lang.org",
                    "PROMOTE_RELEASE_BLOG_SCHEDULED_RELEASE_DATE": event["date"],
                },
            )

        case "publish-rust-dev-stable-rebuild":
            return run_build(
                "promote-release",
                "dev",
                "stable",
                {
                    "PROMOTE_RELEASE_BYPASS_STARTUP_CHECKS": "1",
                },
            )

        case "publish-rust-prod-stable":
            return run_build("promote-release", "prod", "stable")

        case action:
            raise RuntimeError(f"unsupported action: {action}")


def run_build(action, env, channel, extra_vars=None):
    vars = {
        "PROMOTE_RELEASE_ACTION": action,
        "PROMOTE_RELEASE_CHANNEL": channel,
    }
    if extra_vars is not None:
        vars.update(extra_vars)

    build = codebuild.start_build(
        projectName=f"promote-release--{env}",
        environmentVariablesOverride=[
            {"name": name, "value": value, "type": "PLAINTEXT"}
            for name, value in vars.items()
        ],
    )["build"]

    # Continue fetching information about the build
    while "streamName" not in build["logs"]:
        time.sleep(1)
        build = codebuild.batch_get_builds(ids=[build["id"]])["builds"][0]

    return {
        "build_id": build["id"],
        "logs_group": build["logs"]["groupName"],
        "logs_link": build["logs"]["deepLink"],
    }
