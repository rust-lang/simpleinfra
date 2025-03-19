# CI runners

This module configures AWS CodeBuild projects to run CI jobs.

Manual steps required to configure CI runners:

- If you want to add a new repository, you need to edit the settings of the
  GitHub App installed in the organization.
- If you are provisioning this module in a new AWS account,
  you need to [approve](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-update.html)
  the Code Connection that is created by terraform.
- If it is the first time you are configuring a new GitHub organization,
  click on a codebuild project (2c or 4c, etc.) and connect the AWS account
  to the GitHub app manually. If successful, you should see the following message:
  `Your account is successfully connected by using an AWS managed GitHub App.`

## Delay

Note that there's a delay of 2 minutes before the CI job starts in the
AWS CodeBuild runner.
GitHub Actions runners start almost immediately in comparison.
