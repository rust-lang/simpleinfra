// This terraform module imports all the services from the services/ directory,
// and configures them.

module "service_bastion" {
  source                   = "./services/bastion"
  ami_id                   = data.aws_ami.ubuntu_bionic.id
  vpc_id                   = aws_vpc.legacy.id
  subnet_id                = aws_subnet.legacy.id
  common_security_group_id = aws_security_group.legacy_common.id
  key_pair                 = aws_key_pair.buildbot_west_slave_key.key_name

  // Users allowed to connect to the bastion through SSH. Each user needs to
  // have the CIDR of the static IP they want to connect from stored in AWS SSM
  // Parameter Store (us-west-1), in a string key named:
  //
  //     /prod/bastion/allowed-ips/${user}
  //
  allowed_users = [
    "acrichto",
    "aidanhs",
    "guillaumegomez",
    "joshua",
    "mozilla-mountain-view",
    "mozilla-portland",
    "mozilla-san-francisco",
    "onur",
    "pietro",
    "quietmisdreavus",
    "shep",
    "simulacrum",
  ]
}

module "service_rustc_ci" {
  source = "./services/rustc-ci"

  iam_prefix       = "ci--rust-lang--rust"
  caches_bucket    = "rust-lang-ci-sccache2"
  artifacts_bucket = "rust-lang-ci2"
}

module "service_rustc_ci_gha" {
  source = "./services/rustc-ci"

  iam_prefix       = "gha"
  caches_bucket    = "rust-lang-gha-caches"
  artifacts_bucket = "rust-lang-gha"
}

module "service_dev_releases_cdn" {
  source = "./services/releases-cdn"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  bucket             = "dev-static-rust-lang-org"
  static_domain_name = "dev-static.rust-lang.org"
  doc_domain_name    = "dev-doc.rust-lang.org"

  inventories_bucket_arn = aws_s3_bucket.rust_inventories.arn
}

module "service_promote_release" {
  source = "./services/promote-release"

  static_bucket_arn     = "arn:aws:s3:::static-rust-lang-org"
  dev_static_bucket_arn = module.service_dev_releases_cdn.bucket_arn
  ci_bucket_arn         = module.service_rustc_ci.artifacts_bucket_arn
}

module "service_cratesio" {
  source = "./services/cratesio"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  webapp_domain_name = "crates.io"
  static_domain_name = "static.crates.io"
  dns_apex           = true

  static_bucket_name     = "crates-io"
  inventories_bucket_arn = aws_s3_bucket.rust_inventories.arn

  webapp_origin_domain = "crates-io.herokuapp.com"

  iam_prefix = "crates-io"

  logs_bucket = aws_s3_bucket.temp_logs_cratesio.bucket_domain_name
}

module "service_cratesio_staging" {
  source = "./services/cratesio"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  webapp_domain_name = "staging.crates.io"
  static_domain_name = "static.staging.crates.io"

  static_bucket_name     = "staging-crates-io"
  inventories_bucket_arn = aws_s3_bucket.rust_inventories.arn

  webapp_origin_domain = "staging-crates-io.herokuapp.com"

  iam_prefix = "staging-crates-io"
}

module "service_docsrs" {
  source         = "./services/docsrs"
  ecr_repo       = module.ecr_docsrs
  storage_bucket = "rust-docs-rs"
  backups_bucket = "docs.rs-backups"
}

module "service_ecs_cluster" {
  source = "./services/ecs-cluster"

  cluster_name             = "rust-ecs-prod"
  load_balancer_domain     = "ecs-prod.infra.rust-lang.org"
  load_balancer_subnet_ids = module.vpc_prod.public_subnets
  vpc_id                   = module.vpc_prod.id
  subnet_ids               = module.vpc_prod.private_subnets
}

module "service_highfive" {
  source = "./services/highfive"

  domain_name    = "highfive.infra.rust-lang.org"
  cluster_config = module.service_ecs_cluster.config
}

module "service_triagebot" {
  source = "./services/triagebot"

  domain_name    = "triagebot.infra.rust-lang.org"
  cluster_config = module.service_ecs_cluster.config
}
