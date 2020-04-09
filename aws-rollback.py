#!/usr/bin/env python3

import json
import subprocess
import sys

DEFAULT_REPOSITORY_NAME = "rust-central-station"
TARGET_TAG = 'latest'

def main():
    """CLI entrypoint of the program."""
    repository_name = DEFAULT_REPOSITORY_NAME if len(sys.argv) < 2 else sys.argv[1]
    images = get_images(repository_name)
    while True:
        selected_image_index = let_user_pick_image(images)
        if selected_image_index == -1:
            exit(0)

        if not ( selected_image_index is None ):
            break

    image = images[selected_image_index]
    if image["imageTag"] == TARGET_TAG:
        err(f"selected image already tagged as {TARGET_TAG}")

    eprint(f"selected option: {image}")
    manifest = get_image_manifest(repository_name, image["imageTag"])
    retag_image(repository_name,manifest)
    eprint(f"image {image} retaged as '{TARGET_TAG}'")

def let_user_pick_image(images):
    print("Please choosean image to rollback:")
    for idx, image in enumerate(images):
        print("{}) {}".format(idx+1,image["imageTag"]))
    i = input("Enter image number(or 0 to exit): ")
    try:
        idx = int(i)
        if -1 < idx <= len(images):
            return idx-1
    except:
        pass
    return None

def get_images(repository_name):
    """Call ecr to get available images"""
    eprint("obtaining available images")
    try:
        out = json.loads( run_command([
            "aws", "ecr", "list-images",
            "--repository-name", repository_name,
            "--filter", "{\"tagStatus\": \"TAGGED\"}",
            "--no-paginate"
        ]).stdout)
    except subprocess.CalledProcessError as e:
        err(f"failed to get availabe images from repository: {e}" )

    return out["imageIds"]

def get_image_manifest(repository_name, imageTag):
    """Call ecr batch-get-image to get the image manifest"""
    try:
        out = json.loads( run_command([
            "aws", "ecr", "batch-get-image",
            "--repository-name", repository_name,
            "--image-ids", "imageTag={}".format(imageTag)
        ]).stdout)
    except subprocess.CalledProcessError as e:
        err(f"failed to get availabe images from repository: {e}" )

    return out["images"][0]["imageManifest"]


def retag_image(repository_name, manifest):
    """ """
    try:
        out = json.loads( run_command([
            "aws", "ecr", "put-image",
            "--repository-name", repository_name,
            "--image-manifest", manifest,
            "--image-tag", TARGET_TAG
        ]).stdout)
    except subprocess.CalledProcessError as e:
        err(f"failed to tag image as {TARGET_TAG}")

    return True


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
