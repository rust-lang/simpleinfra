# Bucket for private artifacts used by the content team.
# E.g., raw podcast audio files that need to be edited before publishing.
resource "aws_s3_bucket" "internal" {
  bucket = "rust-content-internal"
}

# Block all public access paths so S3 is not directly reachable.
resource "aws_s3_bucket_public_access_block" "internal" {
  bucket = aws_s3_bucket.internal.id

  # Prevent public ACLs from granting access.
  block_public_acls = true
  # Prevent public bucket policies from granting access.
  block_public_policy = true
  # Ignore any public ACLs that might be applied.
  ignore_public_acls = true
  # Restrict public bucket policies.
  restrict_public_buckets = true
}
