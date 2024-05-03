#!/usr/bin/env python3

# Unfortunately Terragrunt is not flexible enough to express all the
# configuration we need in the terragrunt.hcl file. Namely, we need the
# get_aws_account_id() function to check the account ID of the awscli profile
# we're using, but there is no support for that.
#
# To work around the issue we call this script from the terragrunt.hcl file,
# and load the script's JSON output as a Terragrunt local. This allows to
# programmatically define the Terragrunt locals.
#
# To test the script, invoke it in a subdirectory of the directory containing
# the account.json file.

import json
import sys
import os
import subprocess


def find_account_json_file(directory):
    file = os.path.join(directory, "account.json")
    if os.path.exists(file):
        return file
    else:
        parent = os.path.realpath(os.path.join(directory, ".."))
        if parent == directory:
            error("could not find account.json in one of the parent directories")
        return find_account_json_file(parent)


def find_aws_account_id(account_json):
    output = subprocess.run(
        [
            "aws",
            "sts",
            "get-caller-identity",
            *profile_args(account_json),
            "--output",
            "text",
            "--query",
            "Account",
        ],
        stdout=subprocess.PIPE,
        text=True,
    )
    if output.returncode != 0:
        error("failed to retrieve AWS Account ID, are you logged in?")
    return output.stdout.strip()


def calculate_remote_state_key(account_json_file, terragrunt_dir):
    account_json_dir = os.path.realpath(os.path.dirname(account_json_file))
    state_name = os.path.relpath(terragrunt_dir, account_json_dir).rstrip("/")
    return f"{state_name}.tfstate"


def calculate_providers_content(account_json):
    providers = ""

    for region in account_json["aws"]["regions"]:
        body = f'  region = "{region["region"]}"'

        if account_json["aws"]["profile"] is not None:
            body += f'\n  profile = "{account_json["aws"]["profile"]}"'

        if "alias" in region:
            body += f'\n  alias = "{region["alias"]}"'

        providers += f"""
provider "aws" {{
{body}
}}
"""

    return providers


def profile_args(account_json):
    if account_json["aws"]["profile"] is not None:
        return ["--profile", account_json["aws"]["profile"]]
    else:
        return []


def error(message):
    print(f"error: {message}", file=sys.stderr)
    exit(1)


if __name__ == "__main__":
    print(f"terragrunt-locals.py: calculating configuration...", file=sys.stderr)

    if len(sys.argv) != 2:
        error(f"usage: {sys.argv[0]} <terragrunt-dir>")
    terragrunt_dir = sys.argv[1]

    account_json_file = find_account_json_file(terragrunt_dir)
    with open(account_json_file) as f:
        account_json = json.load(f)

    aws_account_id = find_aws_account_id(account_json)
    remote_state_key = calculate_remote_state_key(account_json_file, terragrunt_dir)
    providers_content = calculate_providers_content(account_json)

    data = {
        "remote_state_profile": account_json["aws"]["profile"],
        "remote_state_bucket": f"terraform-state-{aws_account_id}",
        "remote_state_dynamodb_table": "terraform-lock",
        "remote_state_region": "us-east-1",
        "remote_state_key": remote_state_key,
        "providers_content": providers_content,
    }
    print(json.dumps(data, indent=4))
