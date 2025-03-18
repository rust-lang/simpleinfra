# CI runners

Manual steps required to configure CI runners:

- If you want to add a new repository, you need to edit the settings of the
  GitHub App installed in the organization.
- If it is the first time you are configuring a new GitHub organization,
  click on a codebuild project (2c or 4c, etc.) and connect the AWS account
  to the GitHub app manually. If successful, you should see the following message:
  `Your account is successfully connected by using an AWS managed GitHub App.`
