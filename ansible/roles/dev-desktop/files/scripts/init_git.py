#!/usr/bin/python3
import requests
import re
import subprocess
import getpass

for cfg in ["email", "name"]:
    if subprocess.run(["git", "config", "--global", f"user.{cfg}"], stdout=subprocess.DEVNULL).returncode == 0:
        print("git username and email already configured")
        exit(0)

people = requests.get("https://team-api.infra.rust-lang.org/v1/people.json")
people.raise_for_status()
people_map = people.json()["people"]

username = getpass.getuser()
username = username.lstrip("gh-")

print(f"found github name: {username}")

if username not in people_map:
    print("could not find a matching user in the people map!")
    print("E: Could not configure your git name and email. Please do so manually.")
    exit(1)

person = people_map[username]

for config in ["email", "name"]:
    if config not in person:
        print(f"`{config}` variable does not exist")
        continue
    value = person[config]
    r = ["git", "config", "--global", f"user.{config}", value]
    print(str(r))
    subprocess.run(r).check_returncode()

print("successfully configured your user name and email for git")
exit()
