data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}


resource "azurerm_resource_group" "images" {
  name     = var.image_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "build" {
  name     = var.build_resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_resource_group" "network" {
  count    = var.create_network ? 1 : 0
  name     = var.network_resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = var.identity_name
  resource_group_name = azurerm_resource_group.images.name
  location            = azurerm_resource_group.images.location
}

resource "azurerm_role_assignment" "packer_gallery_admin" {
  scope                = azurerm_resource_group.images.id
  role_definition_name = "Compute Gallery Sharing Admin" 
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "image_build_rg_contributor" {
  scope                = azurerm_resource_group.build.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}


resource "azurerm_federated_identity_credential" "github" {

  name                = "github-actions-federated"
  resource_group_name = azurerm_resource_group.images.name
  parent_id           = azurerm_user_assigned_identity.identity.id
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repo}:ref:${var.github_branch}"
  audience            = ["api://AzureADTokenExchange"]
}

module "compute_gallery" {
  source  = "Azure/avm-res-compute-gallery/azurerm"
  version = "0.2.0"

  name                = var.name
  location            = azurerm_resource_group.images.location
  resource_group_name = azurerm_resource_group.images.name
  description         = "Azure Compute Gallery containing versioned GitHub Actions self-hosted runner images"
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  shared_image_definitions = {
    ubuntu2204_runner = {
      name        = "github-runner-ubuntu-2204"
      os_type     = "Linux"
      description = "GitHub Actions Self-Hosted Runner - Ubuntu 22.04 LTS (Jammy Jellyfish) - Gen2 with Trusted Launch"
      identifier = {
        publisher = var.publisher
        offer     = "GitHubActionsRunner"
        sku       = "ubuntu-2204-lts-gen2"
      }
      end_of_life_date = "2027-04-30T00:00:00Z"

      hyper_v_generation = "V1"
      # trusted_launch_enabled              = true
      accelerated_network_support_enabled = true
      architecture                        = "x64"

      min_recommended_vcpu_count   = 2
      max_recommended_vcpu_count   = 32
      min_recommended_memory_in_gb = 8
      max_recommended_memory_in_gb = 128

      tags = {
        OS               = "Ubuntu"
        OSVersion        = "22.04"
        ImageType        = "GitHubActionsRunner"
        HyperVGeneration = "V1"
        SecurityProfile  = "TrustedLaunch"
        BuiltBy          = "Packer"
        Compliance       = "CIS-Level1"
        Owner            = "PlatformEngineering"
        Environment      = "All"
      }
    }
    ubuntu_2404_runner = {
      name        = "github-runner-ubuntu-2404"
      os_type     = "Linux"
      description = "GitHub Actions Self-Hosted Runner - Ubuntu 24.04 LTS (Noble Numbat) - Gen2 with Trusted Launch"
      identifier = {
        publisher = var.publisher
        offer     = "GitHubActionsRunner"
        sku       = "ubuntu-2404-lts-gen2"
      }
      end_of_life_date = "2029-05-31T00:00:00Z"

      hyper_v_generation = "V1"
      # trusted_launch_enabled              = true
      accelerated_network_support_enabled = true
      architecture                        = "x64"

      min_recommended_vcpu_count   = 2
      max_recommended_vcpu_count   = 64
      min_recommended_memory_in_gb = 8
      max_recommended_memory_in_gb = 256

      tags = {
        OS               = "Ubuntu"
        OSVersion        = "24.04"
        ImageType        = "GitHubActionsRunner"
        HyperVGeneration = "V1"
        SecurityProfile  = "TrustedLaunch"
        BuiltBy          = "Packer"
        Compliance       = "CIS-Level1"
        Owner            = "PlatformEngineering"
        Environment      = "All"
      }
    }
  }

  lock    = var.lock != null ? var.lock : null
  sharing = var.sharing
}
