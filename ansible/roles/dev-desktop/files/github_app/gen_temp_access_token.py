import requests
from github import Github
from pprint import pprint

from sys import argv

from datetime import datetime, timedelta, timezone

from github import GithubIntegration

with open('app_id.txt', 'r') as fh:
    app_id = int(fh.read())

with open('dev-desktop.private-key.pem', 'rb') as fh:
    private_key = fh.read()

integration = GithubIntegration(app_id, private_key)

if len(argv) < 2:
    print("usage: <github_username> <github_repo_name>")

installation = integration.get_installation(argv[1], argv[2])

auth = integration.get_access_token(installation.id)

print(auth.token)
