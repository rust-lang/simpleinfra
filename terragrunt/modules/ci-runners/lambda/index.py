import datetime
import io
import json
import os
import subprocess
import uuid
from hashlib import sha256
from zipfile import ZipFile

import boto3

# Download and extract packer at initialization time
# This is intentionally outside of the handler so this is cached if we get
# invoked multiple times.
packer_zip = subprocess.run(
    [
        "curl",
        "https://releases.hashicorp.com/packer/1.16.0/packer_1.16.0_linux_arm64.zip",
        "-o",
        "-",
    ],
    capture_output=True,
    check=True,
)
if (
    sha256(packer_zip.stdout).hexdigest()
    != "cf18f03460d92265d49b56befff333e80641d845822799eab04357c39f75b5d7"
):
    print("Stderr:", packer_zip.stderr)
    print("Got:", sha256(packer_zip.stdout).hexdigest())
    raise RuntimeError("Hash mismatch")
with ZipFile(io.BytesIO(packer_zip.stdout)) as packer_zip:
    packer_zip.extract("packer", path="/tmp/")
os.chmod("/tmp/packer", 0o755)


# TODO: Ideally we'd do some kind of verification the AMI works before we publish it to SSM
# But since it's not super clear how to do that nicely and breakage is relatively unlikely,
# for now we just directly update.
def update_ami(ami_name, arch):
    # Now that we should have an AMI, we want to place it's ID in an SSM parameter.
    # Getting the ID out of packer is annoying so just query EC2 for it from the name.
    ec2 = boto3.client("ec2", region_name="us-east-2")
    ec2_arch = arch if arch == "x86_64" else "arm64"
    images = ec2.describe_images(Owners=["self"], Architecture=[ec2_arch])
    for image in images["Images"]:
        creation_date = datetime.datetime.fromisoformat(image["CreationDate"])
        age_in_days = (
            (
                datetime.datetime.now(datetime.UTC).timestamp()
                - creation_date.timestamp()
            )
            / 3600
            / 24
        )
        if image["Name"] == ami_name:
            ssm = boto3.client("ssm", region_name="us-east-2")
            if arch == "x86_64":
                ssm_name = "latest-gha-runner-ami"
            else:
                ssm_name = "latest-gha-runner-ami-arm64"
            ssm.put_parameter(
                Name=ssm_name,
                Value=image["ImageId"],
                Type="String",
                DataType="aws:ec2:image",
                Overwrite=True,
            )
        elif age_in_days > 14:
            ec2.deregister_image(
                ImageId=image["ImageId"], DeleteAssociatedSnapshots=True
            )


def handler(event, context):
    architecture = event["arch"]

    ami_name = "packer-gha-runner-" + str(uuid.uuid4())
    latest_release = subprocess.run(
        [
            "curl",
            "-H",
            "Accept: application/vnd.github+json",
            "-H",
            "X-GitHub-Api-Version: 2026-03-10",
            "https://api.github.com/repos/actions/runner/releases/latest",
            "-o",
            "-",
        ],
        capture_output=True,
        check=True,
    )
    runner_url = None
    for asset in json.loads(latest_release.stdout)["assets"]:
        url = asset["browser_download_url"]
        if (
            architecture == "x86_64"
            and "linux-x64" in url
            or architecture == "aarch64"
            and "linux-arm64" in url
        ):
            runner_url = url
    # Then execute the packer build
    with_home = os.environ.copy()
    with_home["HOME"] = "/tmp"
    subprocess.run(["/tmp/packer", "init", "ubuntu.pkr.hcl"], check=True, env=with_home)
    subprocess.run(
        [
            "/tmp/packer",
            "build",
            "-var",
            f"ami_name={ami_name}",
            "-var",
            f"runner_url={runner_url}",
            "-var",
            f"architecture={architecture}",
            "ubuntu.pkr.hcl",
        ],
        check=True,
        env=with_home,
    )

    update_ami(ami_name, architecture)
