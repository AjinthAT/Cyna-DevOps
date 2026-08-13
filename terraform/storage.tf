# Stockage d'artefacts, exports et journaux. Cf. CDC section 16 (tableau des
# ressources Azure) : "Storage Account".

resource "azurerm_storage_account" "cyna" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.cyna.name
  location            = azurerm_resource_group.cyna.location

  account_tier             = "Standard"
  account_replication_type = "LRS" # réplication locale : suffisant pour la maquette, à revoir (GRS) pour un vrai PRA

  min_tls_version = "TLS1_2"

  tags = local.common_tags
}

resource "azurerm_storage_container" "exports" {
  name                  = "exports"
  storage_account_name  = azurerm_storage_account.cyna.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "journaux" {
  name                  = "journaux"
  storage_account_name  = azurerm_storage_account.cyna.name
  container_access_type = "private"
}
