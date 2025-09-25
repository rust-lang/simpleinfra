# Rust assets backup

See <https://github.com/rust-lang/infra-team/tree/master/service-catalog/rust-assets-backup>.

## Backup a new bucket

To backup a new bucket, you need to:

1. Create via terraform IAM user for the AWS bucket using the
   [storage_transfer_iam](../../../../terragrunt/modules/storage_transfer_iam/) module.
2. Read the access key id and secret from the AWS SSM Parameter Store.
3. Store these credentials in GCP Secret Manager. For example:

   ```bash
   printf "<access_key_secret>" | gcloud secrets create "<bucket_name>--access-key--<access_key_id>" --data-file=- --project <project_id>
   ```

   Env is `prod` or `dev`.
