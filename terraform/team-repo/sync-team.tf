// CodeBuild project that will run the synchronization, along with the
// CloudWatch log group to store the execution log.

resource "aws_cloudwatch_log_group" "sync_team" {
  name              = "/sync-team"
  retention_in_days = 30
}
