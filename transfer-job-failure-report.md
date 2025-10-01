# Transfer Job Failure Analysis Report

**Date**: September 26, 2025  
**Project**: rust-asset-backup-production  
**Analysis of**: Google Cloud Storage Transfer Service failures

## Executive Summary

The Google Cloud Storage Transfer Service jobs for backing up AWS S3 buckets to GCP are experiencing consistent failures. Two main transfer jobs are affected:

1. **transferJobs/transfer-crates-io** - Backing up production crates-io bucket
2. **transferJobs/transfer-static-rust-lang-org** - Backing up production Rust releases

## Failed Transfer Operations Analyzed

| Operation ID | Job | Status | Start Time | Objects Failed | Bytes Failed |
|--------------|-----|--------|------------|----------------|--------------|
| transferJobs-transfer-crates-io-8112795250505597565 | crates-io | FAILED | 2025-09-26T00:00:01Z | 337 | 9.9 MB |
| transferJobs-transfer-static-rust-lang-org-205732933237355629 | static-rust-lang-org | FAILED | 2025-09-26T00:00:01Z | 5,997 | 381.5 MB |
| transferJobs-transfer-crates-io-14989467690258957078 | crates-io | FAILED | 2025-09-25T18:08:20Z | 130 | 2.3 MB |

## Root Cause Analysis

### Primary Issues Identified

#### 1. Invalid S3 Responses (FAILED_PRECONDITION)
- **Error**: "Received an invalid response from S3"
- **Affected Files**: RSS feeds, OG images, and various content files
- **Impact**: 337 files in latest crates-io operation, 124 files in previous operation

**Example Failed Files from crates-io:**
- `s3://crates-io/rss/crates/agape_layout.xml`
- `s3://crates-io/og-images/aeronet_io.png` 
- `s3://crates-io/rss/crates/apollo-composition.xml`
- `s3://crates-io/og-images/biodivine-lib-bdd.png`

#### 2. S3 Access Denied Errors (PERMISSION_DENIED)
- **Error**: "AccessDenied: Access Denied"
- **Affected Files**: Specific crate files and README content
- **Impact**: 6 files in recent operation

**Example Failed Files:**
- `s3://crates-io/og-images/gh-stats.png`
- `s3://crates-io/crates/gh-stats/gh-stats-0.1.2.crate`
- `s3://crates-io/readmes/moonup/moonup-0.3.1.html`

#### 3. S3 Precondition Failed Errors
- **Error**: "PreconditionFailed: At least one of the pre-conditions you specified did not hold"
- **Severely Affects**: static-rust-lang-org transfers
- **Impact**: 5,997 files failed (nearly 100% failure rate)

**Example Failed Files from static-rust-lang-org:**
- `s3://static-rust-lang-org/dist/2015-01-20/index.html`
- `s3://static-rust-lang-org/dist/2015-02-28/index.html`
- `s3://static-rust-lang-org/dist/2014-12-31/index.html`

## Transfer Configuration Review

### Current Setup
```hcl
# Source: /terraform/shared/modules/assets-backup/transfer.tf
aws_s3_data_source {
  bucket_name       = each.value.bucket_name
  cloudfront_domain = "https://${each.value.cloudfront_id}.cloudfront.net"
  aws_access_key {
    access_key_id     = each.value.aws_access_key_id
    secret_access_key = data.google_secret_manager_secret_version.aws_secret_access_key[each.key].secret_data
  }
}
```

### Buckets Being Transferred
1. **crates-io**: Production crates bucket (CloudFront: d19xqa3lc3clo8)
2. **static-rust-lang-org**: Production Rust releases (CloudFront: d3ah34wvbudrdd)

## Recommendations and Fixes

### Immediate Actions Required

#### 1. Fix CloudFront Domain Configuration
**Issue**: The transfer jobs are configured to use CloudFront domains instead of direct S3 access, which may be causing invalid responses.

**Fix**: Update the transfer configuration to use direct S3 access:

```hcl
# In transfer.tf, remove or comment out the cloudfront_domain
aws_s3_data_source {
  bucket_name = each.value.bucket_name
  # cloudfront_domain = "https://${each.value.cloudfront_id}.cloudfront.net"  # Remove this line
  aws_access_key {
    access_key_id     = each.value.aws_access_key_id
    secret_access_key = data.google_secret_manager_secret_version.aws_secret_access_key[each.key].secret_data
  }
}
```

#### 2. Verify AWS Credentials and Permissions
**Issue**: Access denied errors suggest the AWS access keys may lack sufficient permissions.

**Actions**:
1. Verify the AWS IAM user permissions for the access keys:
   - `AKIA46X5W6CZJH2GD7UE` (crates-io)
   - `AKIA46X5W6CZK2NZZU4U` (static-rust-lang-org)

2. Ensure the IAM policy includes:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::crates-io",
        "arn:aws:s3:::crates-io/*",
        "arn:aws:s3:::static-rust-lang-org",
        "arn:aws:s3:::static-rust-lang-org/*"
      ]
    }
  ]
}
```

#### 3. Add Transfer Options for Better Error Handling
**Fix**: Add transfer options to handle problematic files:

```hcl
transfer_options {
  delete_objects_from_source_after_transfer = false
  overwrite_objects_already_existing_in_sink = true
  # Skip files that consistently fail
  exclude_prefixes = [
    "rss/crates/",  # If RSS feeds are causing issues
  ]
}
```

### Long-term Improvements

#### 1. Implement Retry Logic
- Configure the transfer jobs with retry mechanisms for transient failures
- Set up monitoring and alerting for transfer job failures

#### 2. File-level Filtering
- Analyze which specific files consistently fail and consider excluding them if they're not critical
- Implement a separate process for handling problematic file types

#### 3. CloudFront vs Direct S3 Strategy
- Test both CloudFront and direct S3 approaches to determine optimal configuration
- CloudFront may be causing issues due to caching, redirects, or access patterns

## Impact Assessment

### Current Backup Status
- **crates-io bucket**: Partial backups succeeding (~99% success rate)
  - Recent operation: 634/971 objects copied successfully
  - 326.5 GB of 326.6 GB transferred successfully
  
- **static-rust-lang-org bucket**: Nearly complete failure (~0.02% success rate)
  - Recent operation: Only 1/5,998 objects copied successfully
  - Critical for Rust release artifacts backup

### Business Risk
- **HIGH RISK**: static-rust-lang-org backup is essentially non-functional
- **MEDIUM RISK**: crates-io backup missing some content (RSS feeds, some images)
- **Compliance Risk**: Incomplete backups may not meet disaster recovery requirements

## Next Steps

1. **Immediate** (Today):
   - Remove CloudFront domain configuration and test direct S3 access
   - Verify AWS IAM permissions for both access keys

2. **This Week**:
   - Apply Terraform changes with updated transfer configuration
   - Monitor first transfer operation after changes
   - Implement enhanced error handling options

3. **Within 2 Weeks**:
   - Set up monitoring and alerting for transfer operations
   - Document successful configuration for future reference
   - Consider implementing file-level retry mechanisms

## Files for Reference
- Transfer Configuration: `/terraform/shared/modules/assets-backup/transfer.tf`
- Production Config: `/terraform/assets-backup-prod/backup.tf`
- This Report: `/transfer-job-failure-report.md`