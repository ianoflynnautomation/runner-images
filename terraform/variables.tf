variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "identity_name" {
  type    = string
  default = "github-actions-packer-id"
}

variable "github_repo" {
  type    = string
  default = "yourGithub/project"
}

variable "github_branch" {
  type    = string
  default = "refs/heads/main"
}

variable "image_resource_group_name" {
  type        = string
  description = "The resource group where the image resources will be deployed."
}

variable "build_resource_group_name" {
  type        = string
  description = "The resource group where the build resources will be deployed."
}

variable "network_resource_group_name" {
  type        = string
  description = "The resource group where the build resources will be deployed."
}

variable "create_network" {
  type        = bool
  description = "Whether to create VNet for private builds"
  default     = true
}

variable "publisher" {
  type        = string
  description = "Publisher name for image definitions"
  default     = "MyOrganization"
}

variable "location" {
  type        = string
  description = <<DESCRIPTION
(Required) Azure region where the resource should be deployed.
DESCRIPTION
  nullable    = false
}

variable "gallery_name" {
  type        = string
  description = <<DESCRIPTION
  (Required) Specifies the name of the Shared Image Gallery. Changing this forces a new resource to be created.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9](?:[A-Za-z0-9._-]{0,78}[A-Za-z0-9])?$", var.gallery_name))
    error_message = "The name must be between 1 and 80characters long and can only contain lowercase letters and numbers."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
- `principal_id` - (Required) The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` -(Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. If you are using a condition, valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - (Optional) The type of the principal_id. Possible values are User, Group and ServicePrincipal. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "shared_image_definitions" {
  type = map(object({
    name = string
    identifier = object({
      publisher = string
      offer     = string
      sku       = string
    })
    os_type = string
    purchase_plan = optional(object({
      name      = string
      publisher = optional(string)
      product   = optional(string)
    }))
    description                         = optional(string)
    disk_types_not_allowed              = optional(list(string))
    end_of_life_date                    = optional(string)
    eula                                = optional(string)
    specialized                         = optional(bool)
    architecture                        = optional(string, "x64")
    hyper_v_generation                  = optional(string, "V1")
    max_recommended_vcpu_count          = optional(number)
    min_recommended_vcpu_count          = optional(number)
    max_recommended_memory_in_gb        = optional(number)
    min_recommended_memory_in_gb        = optional(number)
    privacy_statement_uri               = optional(string)
    release_note_uri                    = optional(string)
    trusted_launch_enabled              = optional(bool)
    confidential_vm_supported           = optional(bool)
    confidential_vm_enabled             = optional(bool)
    accelerated_network_support_enabled = optional(bool)
    tags                                = optional(map(string))
  }))
  default     = {}
  description = <<DESCRIPTION
A map to create on the Key shared image definitions
- `name` - (Required) Specifies the name of the Shared Image. Changing this forces a new resource to be created.
- `identifier` - (Required) An identifier object as defined below.
  - `publisher` - (Required) The Publisher Name for this Gallery Image. Changing this forces a new resource to be created.
  - `offer` - (Required) The Offer Name for this Shared Image. Changing this forces a new resource to be created.
  - `sku` - (Required) The Name of the SKU for this Gallery Image. Changing this forces a new resource to be created.- `os_type`  - (Required) The type of Operating System present in this Shared Image. Possible values are Linux and Windows. Changing this forces a new resource to be created.        
- `os_type`  - (Required) The type of Operating System present in this Shared Image. Possible values are Linux and Windows. Changing this forces a new resource to be created.        
- `purchase_plan` - (Optional) A purchase_plan object as defined below.
  - `name` - (Required) The Purchase Plan Name for this Shared Image. Changing this forces a new resource to be created.
  - `publisher` - (Optional) The Purchase Plan Publisher for this Gallery Image. Changing this forces a new resource to be created.
  - `product` - (Optional) The Purchase Plan Product for this Gallery Image. Changing this forces a new resource to be created.
- `description` - (Optional) A description of this Shared Image.
- `disk_types_not_allowed` - (Optional) One or more Disk Types not allowed for the Image. Possible values include Standard_LRS and Premium_LRS.
- `end_of_life_date` - (Optional) The end of life date in RFC3339 format of the Image.
- `eula` - (Optional) The End User Licence Agreement for the Shared Image. Changing this forces a new resource to be created.
- `specialized` - (Optional) Specifies that the Operating System used inside this Image has not been Generalized (for example, sysprep on Windows has not been run). Changing this forces a new resource to be created.
> Note: It's recommended to Generalize images where possible - Specialized Images reuse the same UUID internally within each Virtual Machine, which can have unintended side-effects.
- `architecture` - (Optional) CPU architecture supported by an OS. Possible values are x64 and Arm64. Defaults to x64. Changing this forces a new resource to be created.
- `hyper_v_generation` - (Optional) The generation of HyperV that the Virtual Machine used to create the Shared Image is based on. Possible values are V1 and V2. Defaults to V1. Changing this forces a new resource to be created.
- `max_recommended_vcpu_count` - (Optional) Maximum count of vCPUs recommended for the Image.
- `min_recommended_vcpu_count` - (Optional) Minimum count of vCPUs recommended for the Image.
- `max_recommended_memory_in_gb` - (Optional) Maximum memory in GB recommended for the Image.
- `min_recommended_memory_in_gb` - (Optional) Minimum memory in GB recommended for the Image.
- `privacy_statement_uri` - (Optional) The URI containing the Privacy Statement associated with this Shared Image. Changing this forces a new resource to be created.
- `release_note_uri` - (Optional) The URI containing the Release Notes associated with this Shared Image.
- `trusted_launch_supported` - (Optional) Specifies if supports creation of both Trusted Launch virtual machines and Gen2 virtual machines with standard security created from the Shared Image. Changing this forces a new resource to be created.
- `trusted_launch_enabled` - (Optional) Specifies if Trusted Launch has to be enabled for the Virtual Machine created from the Shared Image. Changing this forces a new resource to be created.
- `confidential_vm_supported` - (Optional) Specifies if supports creation of both Confidential virtual machines and Gen2 virtual machines with standard security from a compatible Gen2 OS disk VHD or Gen2 Managed image. Changing this forces a new resource to be created.
- `confidential_vm_enabled` - (Optional) Specifies if Confidential Virtual Machines enabled. It will enable all the features of trusted, with higher confidentiality features for isolate machines or encrypted data. Available for Gen2 machines. Changing this forces a new resource to be created.
- `accelerated_network_support_enabled` - (Optional) Specifies if the Shared Image supports Accelerated Network. Changing this forces a new resource to be created.
- `tags` - (Optional) A mapping of tags to assign to the Shared Image.
> Note: Only one of `trusted_launch_supported`, `trusted_launch_enabled`, `confidential_vm_supported` and `confidential_vm_enabled` can be specified.
DESCRIPTION
}


variable "sharing" {
  type = object({
    permission = string
    community_gallery = optional(object({
      eula            = string
      prefix          = string
      publisher_email = string
      publisher_uri   = string
    }))
  })
  default     = null
  description = <<DESCRIPTION
A sharing object that supports the following:
- `permission` - (Required) The permission of the Shared Image Gallery when sharing. Possible values are Community, Groups and Private. Changing this forces a new resource to be created.
> Note: This requires that the Preview Feature Microsoft.Compute/CommunityGalleries is enabled, see the documentation for more information.
- `community_gallery` - (Optional) A community_gallery object that supports the following:
  - `eula` - (Required) The End User Licence Agreement for the Shared Image Gallery. Changing this forces a new resource to be created.
  - `prefix` - (Required) Prefix of the community public name for the Shared Image Gallery. Changing this forces a new resource to be created.
  - `publisher_email` - (Required) Email of the publisher for the Shared Image Gallery. Changing this forces a new resource to be created.       
  - `publisher_uri` - (Required) URI of the publisher for the Shared Image Gallery. Changing this forces a new resource to be created.
> Note: `community_gallery` must be set when `permission` is set to `Community`.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
 - `create` - (Defaults to 60 minutes) Used when creating the Shared Image Gallery.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Shared Image Gallery.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Shared Image Gallery.
 - `update` - (Defaults to 60 minutes) Used when updating the Shared Image Gallery.
DESCRIPTION
}


variable "enable_trusted_launch" {
  description = "Enable Trusted Launch for image definitions"
  type        = bool
  default     = false
}
