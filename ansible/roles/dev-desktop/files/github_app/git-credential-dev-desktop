#!/usr/bin/python

from sys import argv, stdin
import os

if argv[1] != "get":
    exit(0)

config = [x.strip() for x in stdin]

if config[1] != "host=github.com":
    exit(0)

path = config[2].split('=')
path = path[1].split('/')

user = path[0]
repo = path[1].rsplit('.', 1)[0]

real_path = os.path.realpath(__file__)
dir_path = os.path.dirname(real_path)

from dump import token

for config in config:
    print(config)

print(f"username={user}")

print(f"password={token(user, repo)}")
print()

