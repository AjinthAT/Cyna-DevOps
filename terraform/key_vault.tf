# Stockage de secrets, clés et certificats. Cf. CDC section 16, tableau des
# ressources Azure : "Key Vault — Stockage de secrets, clés et certificats."

resource "azurerm_key_vault" "cyna" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.cyna.location
  resource_group_name = azurerm_resource_group.cyna.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  # Abonnement étudiant : purge/soft-delete simplifiés pour ne pas bloquer un
  # destroy en fin de projet (voir aussi versions.tf > features > key_vault).
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    default_action = "Allow" # à durcir en "Deny" + IP autorisées pour un déploiement réel
    bypass         = "AzureServices"
  }

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "current_operator" {
  key_vault_id = azurerm_key_vault.cyna.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions      = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  key_permissions         = ["Get", "List", "Create", "Delete", "Purge", "Recover"]
  certificate_permissions = ["Get", "List", "Create", "Delete", "Purge", "Recover"]
}
