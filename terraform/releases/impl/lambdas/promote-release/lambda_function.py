#!/usr/bin/env python3

import os
import json
import urllib.request

import boto3


REPO = "rust-lang/rust"
NIGHTLY_BRANCH = "master"


def handler(event, context):
    s3 = boto3.client("s3")
    codebuild = boto3.client("codebuild")
    ssm = boto3.client("ssm")

    override_branch = event.get("branch")
    channel = event["channel"]

    static_bucket = os.environ["STATIC_BUCKET"]
    static_dir = os.environ["STATIC_DIR"]
    codebuild_project = os.environ["CODEBUILD_PROJECT"]

    github_token = ssm.get_parameter(
        Name = "/prod/promote-release/lambda-github-token",
        WithDecryption = True
    )["Parameter"]["Value"]

    if override_branch is not None:
        branch = override_branch
    elif channel == "nightly":
        branch = NIGHTLY_BRANCH
    else:
        branch = channel

    latest_git_hash = fetch_github_commit(github_token, branch)
    published_git_hash = s3.get_object(
        Bucket = static_bucket,
        Key = f"{static_dir}/channel-rust-{channel}-git-commit-hash.txt",
    )["Body"].read().decode("utf-8")

    if latest_git_hash == published_git_hash:
        return {
            "message": "no need for a release, the latest commit is already published"
        }

    env = {}
    env["PROMOTE_RELEASE_CHANNEL"] = channel
    if override_branch is not None:
        env["PROMOTE_RELEASE_OVERRIDE_CHANNEL"] = override_channel

    codebuild.start_build(
        projectName = codebuild_project,
        environmentVariablesOverride = [
            {
                "name": name,
                "value": value,
                "type": "PLAINTEXT"
            }
            for name, value in env.items()
        ],
    )

    return {
        "message": "release process started!"
    }


def fetch_github_commit(github_token, branch):
    request = urllib.request.Request(f"https://api.github.com/repos/{REPO}/git/refs/heads/{branch}")
    request.add_header("Authorization", f"token {github_token}")
    resp = urllib.request.urlopen(request)

    if resp.getcode() != 200:
        raise RuntimeError(f"failed to get the latest commit: {resp.read()}")
    resp = json.load(resp)

    return resp["object"]["sha"]


handler({
    "channel": "nightly",
}, None)
