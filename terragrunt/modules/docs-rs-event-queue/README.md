# `docs-rs-event-queue`

This module provisions the FIFO SQS queue that carries crates.io index changes
from crates.io to docs.rs.
The queue is deployed in the `us-east-1` region.

- Producer: crates.io
- Consumer: docs.rs

Cross-account consumers can be granted access through the
`consumer_principal_arns` input. The consumer also needs a matching
identity-based IAM policy in its own account.
