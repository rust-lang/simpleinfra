import boto3
import urllib.parse
import urllib.request
import json


ssm = boto3.client("ssm")
codebuild = boto3.client("codebuild")


def handler(event, context):
    if event["rawPath"].startswith("/authorize/"):
        return handler_authorize(event["rawPath"].removeprefix("/authorize/"))
    elif event["rawPath"] == "/callback":
        return handler_callback(event["queryStringParameters"])
    elif event["rawPath"] == "/success":
        return respond_plain(
            200, "Successfully authorized the change, it will be applied soon."
        )
    elif event["rawPath"] == "/unauthorized":
        return respond_plain(403, "You're not authorized to approve sync-team changes.")
    else:
        return respond_plain(404, "404 Not Found\n")


def handler_authorize(hash):
    client_id = ssm.get_parameter(
        Name="/prod/sync-team-confirmation/github-oauth-client-id"
    )["Parameter"]["Value"]

    return respond_redirect(
        f"https://github.com/login/oauth/authorize?client_id={client_id}&state={hash}"
    )


def handler_callback(query):
    parameters = ssm.get_parameters(
        Names=[
            "/prod/sync-team-confirmation/github-oauth-client-id",
            "/prod/sync-team-confirmation/github-oauth-client-secret",
        ],
        WithDecryption=True,
    )
    client_id = parameters["Parameters"][0]["Value"]
    client_secret = parameters["Parameters"][1]["Value"]

    access_token = http_request(
        "POST",
        "https://github.com/login/oauth/access_token",
        form={
            "client_id": client_id,
            "client_secret": client_secret,
            "code": query["code"],
        },
        headers={
            "Accept": "application/json",
        },
    )["access_token"]

    user = http_request(
        "GET",
        "https://api.github.com/user",
        headers={
            "Authorization": f"Bearer {access_token}",
        },
    )

    allowed_users = http_request(
        "GET",
        "https://team-api.infra.rust-lang.org/v1/permissions/sync_team_confirmation.json",
    )
    if user["id"] in allowed_users["github_ids"]:
        codebuild.start_build(
            projectName="sync-team",
            environmentVariablesOverride=[
                {
                    "name": "CONFIRMATION_APPROVED_HASH",
                    "value": query["state"],
                    "type": "PLAINTEXT",
                },
                {
                    "name": "CONFIRMATION_APPROVER",
                    "value": user["login"],
                    "type": "PLAINTEXT",
                },
            ],
        )
        return respond_redirect("/success")
    else:
        return respond_redirect("/unauthorized")


def respond_redirect(url):
    return {
        "statusCode": 302,
        "body": f"Redirecting to {url}\n",
        "headers": {
            "location": url,
            "content-type": "text/plain",
        },
    }


def respond_plain(status, body):
    return {
        "statusCode": status,
        "body": body,
        "headers": {
            "content-type": "text/plain",
        },
    }


def http_request(method, url, *, form=None, headers=None):
    data = None
    if form is not None:
        data = urllib.parse.urlencode(tuple(form.items())).encode("utf-8")

    request = urllib.request.Request(url=url, data=data, method=method)
    request.add_header("user-agent", "sync-team-confirmation (infra@rust-lang.org)")
    if form is not None:
        request.add_header("content-type", "application/x-www-form-urlencoded")
    if headers is not None:
        for key, value in headers.items():
            request.add_header(key, value)
    response = urllib.request.urlopen(request)

    if response.status >= 400:
        raise RuntimeError(f"got status code {response.status} while requesting {url}")

    return json.loads(response.read())
