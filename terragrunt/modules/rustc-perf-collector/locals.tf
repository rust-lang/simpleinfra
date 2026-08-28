locals {
  // Use the bare-metal M9g size so rustc-perf can access the Graviton 5
  // hardware directly, without a hypervisor between the collector and its PMU.
  instance_type = "m9g.metal-48xl"

  availability_zone = "us-east-2a"
}
