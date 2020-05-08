// This terraform module imports all the services from the services/ directory,
// and configures them.

module "service_bastion" {
  source                   = "./services/bastion"
  ami_id                   = data.aws_ami.ubuntu_bionic.id
  vpc_id                   = aws_vpc.legacy.id
  subnet_id                = aws_subnet.legacy.id
  common_security_group_id = aws_security_group.legacy_common.id
  key_pair                 = aws_key_pair.buildbot_west_slave_key.key_name
  allowed_users            = local.allowed_users
}

module "service_rustc_ci" {
  source = "./services/rustc-ci"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  iam_prefix       = "ci--rust-lang--rust"
  caches_bucket    = "rust-lang-ci-sccache2"
  caches_domain    = "ci-caches.rust-lang.org"
  artifacts_bucket = "rust-lang-ci2"
  artifacts_domain = "ci-artifacts.rust-lang.org"
}

module "service_rustc_ci_gha" {
  source = "./services/rustc-ci"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  iam_prefix       = "gha"
  caches_bucket    = "rust-lang-gha-caches"
  caches_domain    = "ci-caches-gha.rust-lang.org"
  artifacts_bucket = "rust-lang-gha"
  artifacts_domain = "ci-artifacts-gha.rust-lang.org"
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
