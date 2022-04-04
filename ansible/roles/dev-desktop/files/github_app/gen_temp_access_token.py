import requests
from github import Github
from pprint import pprint

from sys import argv

from datetime import datetime, timedelta, timezone

from github import GithubIntegration

app_id = 186901

with open('dev-desktop.private-key.pem', 'rb') as fh:
    private_key = fh.read()

integration = GithubIntegration(app_id, private_key)

installation = integration.get_installation(argv[1], argv[2])

auth = integration.get_access_token(installation.id)

print(auth.token)
