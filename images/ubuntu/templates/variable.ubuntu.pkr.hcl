// Authentication related variables
variable "client_cert_path" {
  type    = string
  description = "The path to a PKCS#12 bundle (.pfx file) to be used as the client certificate that will be used to authenticate as the specified AAD SP."
  default = "${env("ARM_CLIENT_CERT_PATH")}"
}

variable "client_id" {
  type    = string
  description = "The application ID of the AAD Service Principal. Requires either client_secret, client_cert_path or client_jwt to be set as well."
  default = "${env("ARM_CLIENT_ID")}"
}

variable "client_secret" {
  type      = string
  description = "A password/secret registered for the AAD SP."
  default   = "${env("ARM_CLIENT_SECRET")}"
  sensitive = true
}

variable "object_id" {
  type    = string
  description = "The object ID for the AAD SP. Optional, will be derived from the oAuth token if left empty."
  default = "${env("ARM_OBJECT_ID")}"
}

variable "oidc_request_token" {
  type    = string
  description = <<DESCRIPTION
OIDC Request Token is used for GitHub Actions OIDC, this token is used with oidc_request_url 
to fetch access tokens to Azure. Value in GitHub Actions can be extracted 
from the ACTIONS_ID_TOKEN_REQUEST_TOKEN variable. Refer to "Configure a federated identity 
credential on an app" for details on how to setup GitHub Actions OIDC authentication.
DESCRIPTION
  default = ""
}

variable "oidc_request_url" {
  type    = string
  description = <<DESCRIPTION
OIDC Request URL is used for GitHub Actions OIDC, together with oidc_request_token to fetch 
access tokens to Azure. Value in GitHub Actions can be extracted from the 
ACTIONS_ID_TOKEN_REQUEST_URL variable.
DESCRIPTION
  default = ""
}

variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}

variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}

variable "use_azure_cli_auth" {
  type    = bool
  description = <<DESCRIPTION
Flag to use Azure CLI authentication. Defaults to false. 
CLI auth will use the information from an active az login session to connect to Azure and set the subscription id and tenant id associated to the signed in account. 
If enabled, it will use the authentication provided by the az CLI. 
Azure CLI authentication will use the credential marked as isDefault and can be verified using az account show. 
Works with normal authentication (az login) and service principals (az login --service-principal --username APP_ID --password PASSWORD --tenant TENANT_ID). 
Ignores all other configurations if enabled.
DESCRIPTION
  default = false
}

// Azure environment related variables
variable "allowed_inbound_ip_addresses" {
  type    = list(string)
  description = <<DESCRIPTION
Specify the list of IP addresses and CIDR blocks that should be allowed access to the VM. 
If provided, an Azure Network Security Group will be created with corresponding rules and be bound to the subnet of the VM. 
Providing allowed_inbound_ip_addresses in combination with virtual_network_name is not allowed.
DESCRIPTION
  default = []
}

variable "azure_tags" {
  type    = map(string)
  description = <<DESCRIPTION
Name/value pair tags to apply to every resource deployed i.e. Resource Group, VM, NIC, VNET, Public IP, KeyVault, etc. 
The user can define up to 50 tags. Tag names cannot exceed 512 characters, and tag values cannot exceed 256 characters.
DESCRIPTION
  default = {}
}

variable "build_resource_group_name" {
  type    = string
  description = "Specify an existing resource group to run the build in."
  default = "${env("BUILD_RG_NAME")}"
}

variable "gallery_image_name" {
  type    = string
  default = "${env("GALLERY_IMAGE_NAME")}"
}

variable "gallery_image_version" {
  type    = string
  description = <<DESCRIPTION
Specify a specific version of an OS to boot from. Defaults to latest. 
There may be a difference in versions available across regions due to image synchronization latency. 
To ensure a consistent version across regions set this value to one that is available in all regions where you are deploying.
DESCRIPTION
  default = "${env("GALLERY_IMAGE_VERSION")}"
}

variable "gallery_name" {
  type    = string
  default = "${env("GALLERY_NAME")}"
}

variable "gallery_resource_group_name" {
  type    = string
  default = "${env("GALLERY_RG_NAME")}"
}

variable "gallery_storage_account_type" {
  type    = string
  default = "${env("GALLERY_STORAGE_ACCOUNT_TYPE")}"
}

variable "image_os_type" {
  type    = string
  default = "Linux"
}

variable "location" {
  type    = string
  description = "Azure datacenter in which your VM will build."
  default = ""
}

variable "managed_image_name" {
  type    = string
  description = <<DESCRIPTION
Specify the managed image name where the result of the Packer build will be saved. 
The image name must not exist ahead of time, and will not be overwritten. 
If this value is set, the value managed_image_resource_group_name must also be set. 
See documentation to learn more about managed images.
DESCRIPTION
  default = ""
}

variable "managed_image_resource_group_name" {
  type    = string
  description = <<DESCRIPTION
Specify the managed image resource group name where the result of the Packer build will be saved. 
The resource group must already exist. If this value is set, the value managed_image_name must also be set. 
See documentation to learn more about managed images.
DESCRIPTION
  default = "${env("ARM_RESOURCE_GROUP")}"
}

variable "managed_image_storage_account_type" {
  type    = string
  description = "Specify the storage account type for a managed image. Valid values are Standard_LRS and Premium_LRS. The default is Standard_LRS."
  default = "Premium_LRS"

validation {
    condition = contains(["Standard_LRS", "Premium_LRS"],var.managed_image_storage_account_type)
    error_message = "Invalid storage account type for managed image. Allowed values are: \"Standard_LRS\", \"Premium_LRS\"."
  }
}

variable "private_virtual_network_with_public_ip" {
  type    = bool
  description = <<DESCRIPTION
This value allows you to set a virtual_network_name and obtain a public IP. 
If this value is not set and virtual_network_name is defined Packer is only allowed to be executed from a host on the same subnet / virtual network.
DESCRIPTION
  default = false
}

variable "os_disk_size_gb" {
  type    = number
  description = "Specify the size of the OS disk in GB (gigabytes). Values of zero or less than zero are ignored."
  default = null
}

variable "source_image_version" {
  type    = string
  default = "latest"
}

variable "ssh_clear_authorized_keys" {
  type    = bool
  description = <<DESCRIPTION
If true, Packer will attempt to remove its temporary key from ~/.ssh/authorized_keys and /root/.ssh/authorized_keys. 
This is a mostly cosmetic option, since Packer will delete the temporary private key from the host system regardless of whether this is set to true (unless the user has set the -debug flag). 
Defaults to "false"; currently only works on guests with sed installed.
DESCRIPTION
  default = true
}

variable "temp_resource_group_name" {
  type    = string
  description = <<DESCRIPTION
Name assigned to the temporary resource group created during the build. 
If this value is not set, a random value will be assigned. 
This resource group is deleted at the end of the build.
DESCRIPTION
  default = "${env("TEMP_RESOURCE_GROUP_NAME")}"
}

variable "virtual_network_name" {
  type    = string
  description = <<DESCRIPTION
Use a pre-existing virtual network for the VM. This option enables private communication with the VM,
no public IP address is used or provisioned (unless you set private_virtual_network_with_public_ip).
DESCRIPTION
  default = "${env("VNET_NAME")}"
}

variable "virtual_network_resource_group_name" {
  type    = string
  description = <<DESCRIPTION
If virtual_network_name is set, this value may also be set. 
If virtual_network_name is set, and this value is not set the builder attempts to determine the resource group containing the virtual network. 
If the resource group cannot be found, or it cannot be disambiguated, this value should be set.
DESCRIPTION
  default = "${env("VNET_RESOURCE_GROUP")}"
}

variable "virtual_network_subnet_name" {
  type    = string
  description = <<DESCRIPTION
If virtual_network_name is set, this value may also be set. 
If virtual_network_name is set, and this value is not set the builder attempts to determine the subnet to use with the virtual network. 
If the subnet cannot be found, or it cannot be disambiguated, this value should be set.
DESCRIPTION
  default = "${env("VNET_SUBNET")}"
}

variable "vm_size" {
  type    = string
  description = "Size of the VM used for building. This can be changed when you deploy a VM from your VHD. See pricing information. Defaults to Standard_A1."
  default = "Standard_D2s_v4"
}

variable "winrm_username" {         // The username used to connect to the VM via WinRM
    type    = string                // Also applies to the username used to create the VM
    default = "packer"
}

// Image related variables
variable "dockerhub_login" {
  type    = string
  default = "${env("DOCKERHUB_LOGIN")}"
}

variable "dockerhub_password" {
  type    = string
  default = "${env("DOCKERHUB_PASSWORD")}"
}

variable "helper_script_folder" {
  type    = string
  default = "/imagegeneration/helpers"
}

variable "image_folder" {
  type    = string
  default = "/imagegeneration"
}

variable "image_os" {
  type    = string
  default = ""
}

variable "image_version" {
  type    = string
  default = "dev"
}

variable "imagedata_file" {
  type    = string
  default = "/imagegeneration/imagedata.json"
}

variable "installer_script_folder" {
  type    = string
  default = "/imagegeneration/installers"
}

variable "install_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "install_user" {
  type    = string
  default = "installer"
}

variable "spot_instance" {
  type = object({
    enabled      = bool
    max_price    = number
    eviction_policy = string
  })
  description = "If set use a spot instance during build; spot configuration settings only apply to the virtual machine launched by Packer and will not be persisted on the resulting image artifact."
  default = {
    enabled      = true
    max_price    = 0.20
    eviction_policy = "Delete"
  }
}

variable "shared_image_gallery_timeout" {
  type    = string
  description = <<DESCRIPTION
How long to wait for an image to be published to the shared image gallery before timing out. 
If your Packer build is failing on the Publishing to Shared Image Gallery step with the error Original 
Error: context deadline exceeded, but the image is present when you check your Azure dashboard,
then you probably need to increase this timeout from its default of "60m" (valid time units include s for seconds, m for minutes, and h for hours.)
DESCRIPTION
  default =  "60m"
}

variable "shared_gallery_image_version_end_of_life_date" {
  type    = string
  description = "The end of life date (2006-01-02T15:04:05.99Z) of the gallery Image Version. This property can be used for decommissioning purposes."
  default = ""
}

variable "shared_gallery_image_version_replica_count" {
  type    = number
  description = "The number of replicas of the Image Version to be created per region defined in replication_regions. Users using target_region blocks can specify individual replica counts per region using the replicas field."
  default = 1
}

variable "shared_gallery_image_version_exclude_from_latest" {
  type    = bool
  description = "f set to true, Virtual Machines deployed from the latest version of the Image Definition won't use this Image Version."
  default = true
}

variable "skip_create_image" {
  type    = bool
  description = "Skip creating the image. Useful for setting to true during a build test stage. Defaults to false."
  default = false
}
