import requests
import os

from github import Github
from pprint import pprint

from sys import argv

from datetime import datetime, timedelta, timezone

from github import GithubIntegration

real_path = os.path.realpath(__file__)
dir_path = os.path.dirname(real_path)


def token(user, repo):
    with open(os.path.join(dir_path, 'app_id.txt'), 'r') as fh:
        app_id = int(fh.read())

    with open(os.path.join(dir_path, 'dev-desktop.private-key.pem'), 'rb') as fh:
        private_key = fh.read()

    integration = GithubIntegration(app_id, private_key)

    installation = integration.get_installation(user, repo)

    auth = integration.get_access_token(installation.id)

    return auth.token


if __name__ == '__main__':
    # executed as script, fetch args and dump result on command line

    if len(argv) < 2:
        print("usage: <github_username> <github_repo_name>")

    print(token(argv[1], argv[2]))
