output "workload_identity_client_id" {
  description = "The Client ID of the User Assigned Identity."
  value       = azurerm_user_assigned_identity.packer.client_id
}

output "gallery_id" {
  description = "Resource ID of the Compute Gallery"
  value       = module.compute_gallery.resource_id
}
