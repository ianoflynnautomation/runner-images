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

resource "azurerm_user_assigned_identity" "packer" {
  name                = var.identity_name
  resource_group_name = azurerm_resource_group.images.name
  location            = azurerm_resource_group.images.location
}

resource "azurerm_role_assignment" "packer_gallery_admin" {
  scope                = azurerm_resource_group.images.id
  role_definition_name = "Compute Gallery Sharing Admin"
  principal_id         = azurerm_user_assigned_identity.packer.principal_id
  description          = "Allows Packer to publish images to Azure Compute Gallery"
}

resource "azurerm_role_assignment" "packer_build_contributor" {
  scope                = azurerm_resource_group.build.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.packer.principal_id
  description          = "Allows Packer to create/delete build resources"
}

resource "azurerm_role_assignment" "packer_vm_contributor" {
  scope                = azurerm_resource_group.images.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.packer.principal_id
  description          = "Allows Packer to manage VMs during image builds"
}

resource "azurerm_role_assignment" "packer_gallery_publisher" {
  scope                = azurerm_resource_group.images.id
  role_definition_name = "Compute Gallery Artifacts Publisher"
  principal_id         = azurerm_user_assigned_identity.packer.principal_id
  description          = "Allows Packer to create and read image versions in the gallery"
}

resource "azurerm_federated_identity_credential" "github_main" {
  name                = "github-actions-main"
  resource_group_name = azurerm_resource_group.images.name
  parent_id           = azurerm_user_assigned_identity.packer.id
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repo}:ref:refs/heads/main"
  audience            = ["api://AzureADTokenExchange"]
}

module "compute_gallery" {
  source  = "Azure/avm-res-compute-gallery/azurerm"
  version = "0.2.0"

  name                = var.gallery_name
  location            = azurerm_resource_group.images.location
  resource_group_name = azurerm_resource_group.images.name
  description         = "Azure Compute Gallery containing versioned GitHub Actions self-hosted runner images"
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  shared_image_definitions = {
    for key, cfg in local.runner_manifest : key => {
      name        = "github-runner-${key}"
      os_type     = cfg.os_type
      description = "GitHub Actions Runner: ${cfg.os_type} ${cfg.version}"

      identifier = {
        publisher = var.publisher
        offer     = "GitHubActionsRunner"
        sku       = cfg.sku
      }

      end_of_life_date             = cfg.eol
      hyper_v_generation           = "V1"
      architecture                 = "x64"
      min_recommended_vcpu_count   = 2
      max_recommended_vcpu_count   = cfg.max_vcpu
      min_recommended_memory_in_gb = 8
      max_recommended_memory_in_gb = cfg.max_mem

      tags = merge(local.base_image_tags, {
        OS              = cfg.os_type
        OSVersion       = cfg.version
        SecurityProfile = var.enable_trusted_launch ? "TrustedLaunch" : "Standard"
      })
    }
  }

  lock    = var.lock != null ? var.lock : null
  sharing = var.sharing
}
