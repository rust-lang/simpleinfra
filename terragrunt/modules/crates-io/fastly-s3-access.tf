resource "aws_iam_user" "fastly_s3_index_reader" {
  name = "${var.iam_prefix}-fastly-s3-index-reader"
}

resource "aws_iam_access_key" "fastly_s3_index_reader" {
  user = aws_iam_user.fastly_s3_index_reader.name
}
