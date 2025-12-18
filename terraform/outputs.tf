output "workload_identity_client_id" {
  description = "The Client ID of the User Assigned Identity."
  value       = azurerm_user_assigned_identity.identity.client_id
}
