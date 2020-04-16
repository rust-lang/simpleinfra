#!/usr/bin/env python3

import json
import subprocess
import sys

TARGET_TAG = 'latest'
ECS_CLUSTER = 'rust-ecs-prod'

def main():
    """CLI entrypoint of the program."""
    if len(sys.argv) < 2:
        usage()
    repository_name = sys.argv[1]
    images = get_images(repository_name)
    while True:
        selected_image_index = let_user_pick_image(images)
        if selected_image_index == -1:
            exit(0)

        if selected_image_index is not None:
            break

    image = images[selected_image_index]
    if image["imageTag"] == TARGET_TAG:
        err(f"selected image already tagged as {TARGET_TAG}")

    eprint(f"selected option: {image}")
    manifest = get_image_manifest(repository_name, image["imageTag"])
    retag_image(repository_name,manifest)
    eprint(f"image {image} retaged as '{TARGET_TAG}'")
    if can_redeploy(repository_name):
        redeployed = force_redeploy()
        if redeployed:
            eprint(f"successfully rollback and re-deploy")

def let_user_pick_image(images):
    print("Please choose an image to rollback:")
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
        err(f"failed to re-tag image as {TARGET_TAG}")

    return True

def can_redeploy(repository_name):
    """return True IFF there is a service with the same name of the repository."""
    try:
        out = json.loads( run_command([
            "aws", "ecs", "list-services",
            "--cluster", ECS_CLUSTER,
            "--no-paginate"
        ]).stdout)

        services = out["serviceArns"]
        for service in services:
            # last part of arn is the service name.
            if repository_name == service.split('/')[-1]:
                return True

        return False
    except subprocess.CalledProcessError as e:
        err(f"failed to list services in cluste {ECS_CLUSTER}")

def force_redeploy(service_name):
    """Force redeploy on ecs"""
    try:
        out = json.loads( run_command([
            "aws", "ecs", "update-service",
            "--cluster", ECS_CLUSTER,
            "--service", service_name,
            "--force-new-deployment"
        ]).stdout)

        return True
    except subprocess.CalledProcessError as e:
        err(f"failed to re-deploy service {service_name}")


###############
#  Utilities  #
###############

def usage():
    """ print usage help and exit."""
    print("error: missing argument, you need to pass the repository name to use. e.g:")
    print("aws-rollback.py <repository name>")
    exit(1)

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
