resource "aws_iam_role" "user-role-tf" {
  name = var.rolename
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : var.remote-arn
          },
          "Action" : "sts:AssumeRole",
          "Condition" : {
            "StringEquals" : {
              "sts:ExternalId" : var.external-id
            }
          }
        }
      ]
    }
  )
}

data "aws_iam_policy" "view_only_access" {
  arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

data "aws_iam_policy" "security_audit" {
  arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "view_only_access_role_policy_attach" {
  role       = aws_iam_role.user-role-tf.name
  policy_arn = data.aws_iam_policy.view_only_access.arn
}
resource "aws_iam_role_policy_attachment" "security_audit_role_policy_attach" {
  role       = aws_iam_role.user-role-tf.name
  policy_arn = data.aws_iam_policy.security_audit.arn
}
