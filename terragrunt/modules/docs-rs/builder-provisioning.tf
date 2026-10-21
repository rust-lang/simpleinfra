locals {
  builder_user_data = "#cloud-config\n${yamlencode({
    package_update = true
    packages       = ["ca-certificates", "curl", "jq", "unzip", "docker.io"]
    write_files = concat([
      {
        path        = "/etc/docs-rs/host.json"
        permissions = "0644"
        content = jsonencode({
          region      = data.aws_region.builder.region
          asg_name    = local.builder_asg_name
          launch_hook = local.builder_launch_hook
          image       = local.builder_image
          log_group   = aws_cloudwatch_log_group.builder.name
          prefix      = local.builder_prefix_path
          workspace   = local.builder_workspace_path
          environment = local.builder_environment
          secrets = {
            DOCSRS_DATABASE_URL       = aws_ssm_parameter.connection_url.name,
            DOCSRS_GITHUB_ACCESSTOKEN = local.github_token_parameter
          }
          runsc_version = "20261012.0"
          runsc_sha256  = "7a440a035128a52f489b0bb76f60ac4df9cabe7cdf31dd5fd79a3e80f8a707ca"
        })
      }
      ], [for destination, source in {
        "/etc/docker/daemon.json"                   = "builder-docker.json"
        "/usr/local/sbin/docs-rs-builder"           = "builder-launcher.sh"
        "/usr/local/sbin/docs-rs-builder-bootstrap" = "builder-startup.sh"
        "/etc/systemd/system/builder.service"       = "builder.service"
        } : {
        path        = destination
        permissions = startswith(destination, "/usr/local/sbin/") ? "0755" : "0644"
        # Docker must be installed before its custom runtime configuration is written.
        defer   = true
        content = file("${path.module}/templates/${source}")
    }])
    runcmd = [["/usr/local/sbin/docs-rs-builder-bootstrap"]]
  })}"
}
