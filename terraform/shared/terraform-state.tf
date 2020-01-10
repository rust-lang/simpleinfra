// This file contains the definition of the resources needed to store the
// Terraform State, **except** the underlying S3 bucket and DynamoDB table.
//
// Those are not configured through Terraform to avoid cyclic dependencies: the
// cycle could make solving issues if things go wrong way harder.

data "aws_s3_bucket" "rust_terraform" {
  bucket = "rust-terraform"
}

// Not all the administrators should be able to access the Terraform state.
// Because of that the bucket has a policy to deny access to everyone except
// selected infra team members and the root account.
//
// https://aws.amazon.com/blogs/security/how-to-restrict-amazon-s3-bucket-access-to-a-specific-iam-role/
resource "aws_s3_bucket_policy" "rust_terraform" {
  bucket = data.aws_s3_bucket.rust_terraform.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::rust-terraform",
        "arn:aws:s3:::rust-terraform/*"
      ],
      "Condition": {
        "StringNotLike": {
          "aws:userId": [
            "${data.aws_caller_identity.current.account_id}",
            "${aws_iam_user.acrichto.unique_id}",
            "${aws_iam_user.aidanhs.unique_id}",
            "${aws_iam_user.pietro.unique_id}",
            "${aws_iam_user.simulacrum.unique_id}"
          ]
        }
      }
    }
  ]
}
EOF
}
