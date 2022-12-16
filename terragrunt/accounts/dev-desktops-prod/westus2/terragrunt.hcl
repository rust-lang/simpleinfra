terraform {
  source = "../../../modules//dev-desktops-azure"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

include "azure" {
  path = find_in_parent_folders("azure-provider.hcl")
  merge_strategy = "deep"
}

dependency "resource_group" {
  config_path = "../resource-group"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location = "West US 2"
  instances = {
    "dev-desktop-us-2" = {
      instance_type = "Standard_F32s_v2"
      storage       = 1000
    }
  }
}
