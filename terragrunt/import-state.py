#!/usr/bin/env python3

# Import Terraform state into terragrunt
#
# This script can be used to import the state of a given Terraform module into
# the terragrunt configuration in the current directory. The script only
# performs non-destructive imports into the terragrunt state, and leaves the
# original Terraform state untouched.
#
# The following example will import all resources that start with module.staging
# from the Terraform module at `/terraform/crates-io`, except for the IAM policy
# for Heroku.
#
#     import-state.py \
#       -t crates-io \
#       -p module.staging \
#       --ignore 'module.prod.aws_iam_user_policy_attachment.heroku_static_write'

import argparse
import json
import os
import subprocess

from collections import namedtuple
from typing import Optional


Config = namedtuple(
    "Config",
    [
        "terraform_module_path",
        "terragrunt_config_path",
        "terraform_resource_prefix",
        "ignored_resources",
        "dry_run",
        "debug",
    ],
)


def main():
    args = parse_arguments()
    config = init_config(args)

    confirm_or_exit(config)

    terraform_resources = load_terraform_resources(config)
    terragrunt_resources = load_terragrunt_resources(config)

    resources = filter_managed_resources(config, terraform_resources)
    resources = filter_ignored_resources(config, resources)
    resources = filter_existing_resources(config, resources, terragrunt_resources)

    ids = get_ids_for_resources(resources)

    import_resources(config, ids)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import Terraform state into terragrunt"
    )

    parser.add_argument(
        "-t",
        "--terraform",
        help="Name of the Terraform module (e.g. bastion)",
        required=True,
    )
    parser.add_argument(
        "-p",
        "--prefix",
        help="Prefix to filter Terraform resources (e.g. module.staging)",
        required=True,
    )
    parser.add_argument(
        "--ignore",
        help="Address of a resource in Terraform that should not be imported",
        nargs="*",
    )
    parser.add_argument(
        "--debug",
        help="Enable debug logging",
        action="store_true",
    )
    parser.add_argument(
        "--dry-run",
        help="Print import commands instead of running them",
        action="store_true",
    )

    return parser.parse_args()


def init_config(args: argparse.Namespace) -> Config:
    if args.debug:
        print("DEBUG initializing configuration...")

    terraform_module_path = init_terraform_module_path(args.terraform)
    terragrunt_config_path = os.getcwd()

    terraform_prefix = args.prefix
    ignored_resources = [] if args.ignore is None else args.ignoret
    debug = args.debug
    dry_run = args.dry_run

    config = Config(
        terraform_module_path,
        terragrunt_config_path,
        terraform_prefix,
        ignored_resources,
        dry_run,
        debug,
    )

    if config.debug:
        print(config)

    return config


def init_terraform_module_path(name: str) -> str:
    script_path = os.path.realpath(__file__)

    terraform_path = os.path.abspath(
        os.path.join(script_path, "..", "..", "terraform", name)
    )

    if not os.path.isdir(terraform_path):
        raise Exception("ERROR failed to find Terraform module with name " + name)

    return terraform_path


def confirm_or_exit(config: Config) -> None:
    script_path = os.path.realpath(__file__)
    simpleinfra_path = os.path.abspath(os.path.join(script_path, "..", ".."))

    relative_terraform_path = os.path.relpath(
        config.terraform_module_path, simpleinfra_path
    )
    relative_terragrunt_path = os.path.relpath(
        config.terragrunt_config_path, simpleinfra_path
    )

    print("\nPlease review the following parameters:\n")
    print("  From: " + relative_terraform_path)
    print("  To:   " + relative_terragrunt_path)
    print("\nPrefix: " + config.terraform_resource_prefix)

    if config.dry_run:
        print("\nSkipping confirmation in dry run")
    else:
        confirmation = input(
            "\nConfirm these settings by pressing 'y', or abort with any other input.\n"
        )

        if confirmation not in ("y", "Y", "yes"):
            print("\nExiting without changes.")
            exit(0)


def load_terraform_resources(config: Config) -> [dict]:
    command = ["terraform", "show", "-json"]
    cwd = config.terraform_module_path

    state_as_json = run_command(config, command, cwd)
    state = json.loads(state_as_json)

    child_module = filter_child_modules(state, config.terraform_resource_prefix)

    if child_module is None:
        if config.debug:
            print(
                "DEBUG failed to find child module with address "
                + config.terraform_resource_prefix
                + " in state"
            )

        return []

    resources = child_module["resources"]

    if config.debug:
        print("DEBUG found " + str(len(resources)) + " resources in Terraform")

    return resources


def load_terragrunt_resources(config: Config) -> [dict]:
    command = ["terragrunt", "show", "-json"]
    cwd = config.terragrunt_config_path

    state_as_json = run_command(config, command, cwd)
    state = json.loads(state_as_json)

    if "values" in state:
        resources = state["values"]["root_module"]["resources"]
    else:
        resources = []

    if config.debug:
        print("DEBUG found " + str(len(resources)) + " resources in terragrunt")

    return resources


def run_command(config: Config, command: [str], cwd: str) -> bytes:
    if config.debug:
        print("DEBUG running '" + " ".join(command) + "' in " + cwd)

    return subprocess.run(command, check=True, capture_output=True, cwd=cwd).stdout


def filter_child_modules(state: dict, prefix: str) -> Optional[dict]:
    for module in state["values"]["root_module"]["child_modules"]:
        if module["address"] == prefix:
            return module


def filter_managed_resources(config: Config, items: [dict]) -> [dict]:
    resources = list(filter(lambda item: item["mode"] == "managed", items))

    if config.debug:
        filtered_count = len(items) - len(resources)
        print(
            "DEBUG filtered "
            + str(filtered_count)
            + " items that are not managed by the Terraform module"
        )

    return resources


def filter_ignored_resources(config: Config, items: [dict]) -> [dict]:
    resources = list(
        filter(lambda item: item["address"] not in config.ignored_resources, items)
    )

    if config.debug:
        filtered_count = len(items) - len(resources)
        print("DEBUG ignoring " + str(filtered_count) + " resources in Terraform")

    return resources


def filter_existing_resources(
    config: Config, terraform_resources: [dict], terragrunt_resources: [dict]
) -> [dict]:
    existing_addresses = list(
        map(
            lambda item: config.terraform_resource_prefix + "." + item["address"],
            terragrunt_resources,
        )
    )
    resources = list(
        filter(
            lambda item: item["address"] not in existing_addresses, terraform_resources
        )
    )

    if config.debug:
        filtered_count = len(terraform_resources) - len(resources)
        print(
            "DEBUG ignoring "
            + str(filtered_count)
            + " resources that already exist in terragrunt"
        )

    return resources


def get_ids_for_resources(resources: [dict]) -> dict:
    ids = {}

    for resource in resources:
        address = resource["address"]
        id = resource["values"]["id"]

        ids[address] = id

    return ids


def import_resources(config: Config, ids: dict):
    print("\nFound " + str(len(ids)) + " resources to import")

    for address, id in ids.items():
        terragrunt_address = address.removeprefix(
            config.terraform_resource_prefix + "."
        )

        cmd = ["terragrunt", "import", terragrunt_address, id]

        if config.debug and not config.dry_run:
            print("DEBUG " + " ".join(cmd))

        if config.dry_run:
            print(" ".join(cmd))
        else:
            subprocess.run(cmd, check=True, cwd=config.terragrunt_config_path)


if __name__ == "__main__":
    main()
