// Terraform requires some state to be persisted between runs. This file
// configures storage and locking support on S3 and DynamoDB.
//
// https://www.terraform.io/docs/backends/index.html
// https://www.terraform.io/docs/backends/types/s3.html

resource "aws_s3_bucket" "rust_terraform" {
  bucket = "rust-terraform"
  acl    = "private"

  // Not all the administrators should be able to access the Terraform state.
  // Because of that the bucket has a policy to deny access to everyone except
  // selected infra team members and the root account.
  //
  // https://aws.amazon.com/blogs/security/how-to-restrict-amazon-s3-bucket-access-to-a-specific-iam-role/
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

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
