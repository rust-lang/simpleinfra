# Keep the quota request in its own state because AWS may require manual review
# and take time to approve it. The collector state can then fail cleanly before
# creating billable infrastructure while this request is pending.
terraform {
  source = "../../../modules//rustc-perf-quota"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  # Dedicated Host quotas count allocated physical hosts rather than the vCPUs
  # of the instances placed on them. One host can be partitioned into several
  # M9g instances after AWS approves this increase from the default of zero.
  dedicated_host_limit = 1
}
