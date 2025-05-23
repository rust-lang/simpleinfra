data "aws_ssoadmin_instances" "rust" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.rust.identity_store_ids[0]
  instance_arn      = data.aws_ssoadmin_instances.rust.arns[0]
}

# The various user groups

resource "aws_identitystore_group" "infra-admins" {
  identity_store_id = local.identity_store_id

  display_name = "infra-admins"
  description  = "The administrators of the Rust organization"
}

resource "aws_identitystore_group" "infra" {
  identity_store_id = local.identity_store_id

  display_name = "infra"
  description  = "The infrastructure team"
}

resource "aws_identitystore_group" "billing" {
  identity_store_id = local.identity_store_id

  display_name = "billing"
  description  = "People with access to the billing portal"
}

resource "aws_identitystore_group" "crates_io" {
  identity_store_id = local.identity_store_id

  display_name = "crates-io"
  description  = "The crates.io team"
}

resource "aws_identitystore_group" "metrics_initiative" {
  identity_store_id = local.identity_store_id

  display_name = "metrics-initiative"
  description  = "The metrics-initiative team"
}

resource "aws_identitystore_group" "triagebot" {
  identity_store_id = local.identity_store_id

  display_name = "triagebot"
  description  = "The triagebot maintainers"
}

resource "aws_identitystore_group" "release" {
  identity_store_id = local.identity_store_id

  display_name = "release"
  description  = "The release team"
}

# The different permission sets a group may have assigned to it

resource "aws_ssoadmin_permission_set" "administrator_access" {
  instance_arn = local.instance_arn
  name         = "AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_access" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
}

resource "aws_ssoadmin_permission_set" "billing_access" {
  instance_arn = local.instance_arn
  name         = "BillingAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "billing_access" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
  permission_set_arn = aws_ssoadmin_permission_set.billing_access.arn
}

resource "aws_ssoadmin_permission_set" "view_only_access" {
  instance_arn = local.instance_arn
  name         = "ViewOnlyAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "view_only_access" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.view_only_access.arn
}

// Grants limited but additional access from ViewOnlyAccess -- e.g., to logs.
// We will expand this mostly as needed without granting write access.
// This role should only be granted in accounts that are scoped to a single
// service (i.e., not our legacy account), because that automatically scopes access.
resource "aws_ssoadmin_permission_set" "read_only_access" {
  instance_arn = local.instance_arn
  name         = "ReadOnlyAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only_access" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only_access.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "no_kms" {
  inline_policy      = data.aws_iam_policy_document.no_kms.json
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only_access.arn
}

data "aws_iam_policy_document" "no_kms" {
  statement {
    sid       = "DropKMSDecrypt"
    effect    = "Deny"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

// Triagebot team read-only access into the legacy account.
resource "aws_ssoadmin_permission_set" "triagebot_access" {
  instance_arn = local.instance_arn
  name         = "TriagebotReadOnly"
}

data "aws_iam_policy_document" "triagebot_access" {
  statement {
    sid    = "ReadLogs"
    effect = "Allow"
    actions = [
      // Subset of CloudwatchReadOnlyAccess
      // See https://docs.aws.amazon.com/aws-managed-policy/latest/reference/CloudWatchReadOnlyAccess.html
      "logs:Get*",
      "logs:List*",
      "logs:StartQuery",
      "logs:Describe*",
      "logs:FilterLogEvents",
      "logs:StartLiveTail",
      "logs:StopLiveTail",
    ]
    resources = [
      "arn:aws:logs:us-west-1:890664054962:log-group:/ecs/triagebot",
      "arn:aws:logs:us-west-1:890664054962:log-group:/ecs/triagebot:*",
    ]
  }

  statement {
    sid    = "NonResourceStatement"
    effect = "Allow"
    actions = [
      // Subset of CloudwatchReadOnlyAccess
      // See https://docs.aws.amazon.com/aws-managed-policy/latest/reference/CloudWatchReadOnlyAccess.html
      "logs:StopQuery",
      "logs:DescribeLogGroups",
      "logs:DescribeQueries",
      "logs:DescribeQueryDefinitions",
      "logs:TestMetricFilter",
    ]
    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "triagebot_access" {
  inline_policy      = data.aws_iam_policy_document.triagebot_access.json
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.triagebot_access.arn
}

// Release team permission to start a new release

resource "aws_ssoadmin_permission_set" "start_release" {
  instance_arn = local.instance_arn
  name         = "StartRelease"
}

resource "aws_ssoadmin_permission_set_inline_policy" "start_release" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.start_release.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:us-west-1:890664054962:function:start-release"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StopBuild",
        ]
        Resource = [
          "arn:aws:codebuild:us-west-1:890664054962:project/promote-release--dev",
          "arn:aws:codebuild:us-west-1:890664054962:project/promote-release--prod",
        ]
      },
      {
        // This is a safeguard to ensure members of the release team can never
        // start any CodeBuild job directly, but rather have to go through the
        // lambda. This is because the StartBuild permission not only allows
        // starting the build (which would be fine), but also override any part
        // of the build definition, including the executed steps.
        Effect   = "Deny"
        Action   = "codebuild:StartBuild"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          // Subset of CloudwatchReadOnlyAccess
          // See https://docs.aws.amazon.com/aws-managed-policy/latest/reference/CloudWatchReadOnlyAccess.html
          "logs:Get*",
          "logs:List*",
          "logs:StartQuery",
          "logs:Describe*",
          "logs:FilterLogEvents",
          "logs:StartLiveTail",
          "logs:StopLiveTail",
        ]
        Resource = [
          "arn:aws:logs:us-west-1:890664054962:log-group:/dev/promote-release",
          "arn:aws:logs:us-west-1:890664054962:log-group:/dev/promote-release:*",
          "arn:aws:logs:us-west-1:890664054962:log-group:/prod/promote-release",
          "arn:aws:logs:us-west-1:890664054962:log-group:/prod/promote-release:*",
        ]
      },
    ]
  })
}

# The assignment of groups to accounts with their respective permission sets

locals {
  assignments = [
    # Admin
    {
      account : aws_organizations_account.admin,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.billing,
        permissions : [aws_ssoadmin_permission_set.billing_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access] }
      ]
    },
    # Legacy
    {
      account : aws_organizations_account.legacy,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.billing,
        permissions : [aws_ssoadmin_permission_set.billing_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.view_only_access] },
        { group : aws_identitystore_group.triagebot,
        permissions : [aws_ssoadmin_permission_set.triagebot_access] },
        { group : aws_identitystore_group.release,
        permissions : [aws_ssoadmin_permission_set.start_release] },
      ]
    },
    # crates-io Staging
    {
      account : aws_organizations_account.crates_io_staging,
      groups : [
        { group : aws_identitystore_group.infra-admins,
          permissions : [
            aws_ssoadmin_permission_set.read_only_access,
            aws_ssoadmin_permission_set.administrator_access
        ] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.crates_io,
        permissions : [aws_ssoadmin_permission_set.read_only_access] },
      ]
    },
    # crates-io Production
    {
      account : aws_organizations_account.crates_io_prod,
      groups : [
        { group : aws_identitystore_group.infra-admins,
          permissions : [
            aws_ssoadmin_permission_set.read_only_access,
            aws_ssoadmin_permission_set.administrator_access
        ] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.crates_io,
        permissions : [aws_ssoadmin_permission_set.read_only_access] },
      ]
    },
    # docs-rs Staging
    {
      account : aws_organizations_account.docs_rs_staging,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
      ]
    },
    # Dev-Desktops Prod
    {
      account : aws_organizations_account.dev_desktops_prod,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access] }
      ]
    },
    # bors staging
    {
      account : aws_organizations_account.bors_staging,
      groups : [
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
      ]
    },
    # bors prod
    {
      account : aws_organizations_account.bors_prod,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access] },
      ]
    },
    # ci staging
    {
      account : aws_organizations_account.ci_staging,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access] },
      ]
    },
    # ci prod
    {
      account : aws_organizations_account.ci_prod,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access] },
      ]
    },
    # metrics initiative prod
    {
      account : aws_organizations_account.metrics_initiative_prod,
      groups : [
        { group : aws_identitystore_group.infra-admins,
        permissions : [aws_ssoadmin_permission_set.read_only_access, aws_ssoadmin_permission_set.administrator_access] },
        { group : aws_identitystore_group.infra,
        permissions : [aws_ssoadmin_permission_set.read_only_access] },
        { group : aws_identitystore_group.metrics_initiative,
        permissions : [aws_ssoadmin_permission_set.read_only_access] },
      ]
    },
  ]
}

module "sso_account_assignment" {
  for_each   = { for assignment in local.assignments : assignment.account.name => assignment }
  source     = "./sso-account-assignment"
  account_id = each.value.account.id
  groups     = each.value.groups
}
