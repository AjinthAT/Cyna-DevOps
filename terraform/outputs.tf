output "resource_group_name" {
  value = azurerm_resource_group.cyna.name
}

output "vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "subnet_ids" {
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
  description = "IDs des sous-réseaux du hub, indexés par nom (GatewaySubnet, SNET-MGMT, SNET-SECURITY, SNET-BACKUP, SNET-PRA)."
}

output "key_vault_uri" {
  value = azurerm_key_vault.cyna.vault_uri
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.cyna.workspace_id
}

output "log_analytics_primary_shared_key" {
  value     = azurerm_log_analytics_workspace.cyna.primary_shared_key
  sensitive = true
}

output "recovery_services_vault_name" {
  value = azurerm_recovery_services_vault.cyna.name
}

output "storage_account_name" {
  value = azurerm_storage_account.cyna.name
}

output "vpn_gateway_public_ip" {
  value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : null
  description = "Null si enable_vpn_gateway = false."
}
