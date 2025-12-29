locals {
  base_image_tags = {
    ImageType   = "GitHubActionsRunner"
    BuiltBy     = "Packer"
    Compliance  = "CIS-Level1"
    Owner       = "PlatformEngineering"
    Environment = "All"
    ManagedBy   = "Terraform"
  }

  runner_manifest = {
    "ubuntu-2204" = {
      os_type  = "Linux"
      version  = "22.04"
      sku      = "ubuntu-2204-lts-gen2"
      eol      = "2027-04-30T00:00:00Z"
      max_vcpu = 32
      max_mem  = 128
    }
    "ubuntu-2404" = {
      os_type  = "Linux"
      version  = "24.04"
      sku      = "ubuntu-2404-lts-gen2"
      eol      = "2029-05-31T00:00:00Z"
      max_vcpu = 64
      max_mem  = 256
    }
    # "win11" = {
    #   os_type  = "Windows"
    #   version  = "Windows-11"
    #   sku      = "win11-22h2-pro-gen2"
    #   eol      = "2026-10-01T00:00:00Z"
    #   max_vcpu = 16
    #   max_mem  = 64
    # }
    # "win2022" = {
    #   os_type  = "Windows"
    #   version  = "Server-2022"
    #   sku      = "2022-datacenter-azure-edition"
    #   eol      = "2031-10-14T00:00:00Z"
    #   max_vcpu = 32
    #   max_mem  = 128
    # }
  }
}
