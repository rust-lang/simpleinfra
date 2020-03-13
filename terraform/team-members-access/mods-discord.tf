// This file defines the permissions of mods-discord team members with access
// to discord-mods-bot's production environment.

resource "aws_iam_group" "mods_discord" {
  name = "mods-discord"
}

resource "aws_iam_group_policy_attachment" "mods_discord_manage_own_credentials" {
  group      = aws_iam_group.mods_discord.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "mods_discord_enforce_mfa" {
  group      = aws_iam_group.mods_discord.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

data "aws_cloudwatch_log_group" "ecs_discord_mods_bot" {
  name = "/ecs/discord-mods-bot"
}

resource "aws_iam_group_policy" "mods_discord" {
  group = aws_iam_group.mods_discord.name
  name  = "prod-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Log access for the discord-mods-bot ECS service.
      //
      // This block allows team members to navigate the CloudWatch console to
      // inspect logs produced by their application.
      {
        Sid    = "AllowListingAllLogs"
        Effect = "Allow"
        Action = [
          // List all logs group in the account, needed for the console
          "logs:DescribeLogGroups",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowAccessToOwnLogs"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:DescribeSubscriptionFilters",
          "logs:FilterLogEvents",
          "logs:GetLogEvents",
        ]
        Resource = data.aws_cloudwatch_log_group.ecs_discord_mods_bot.arn,
      },
    ]
  })
}
