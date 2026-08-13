# Sauvegarde et restauration cloud. Cf. CDC section 16 (tableau des
# ressources Azure) et section 17 "PRA/PCA et sauvegardes".

resource "azurerm_recovery_services_vault" "cyna" {
  name                = var.recovery_vault_name
  location            = azurerm_resource_group.cyna.location
  resource_group_name = azurerm_resource_group.cyna.name
  sku                 = "Standard"

  soft_delete_enabled = true

  tags = local.common_tags
}

# Politique de sauvegarde par défaut pour les VM (quotidienne, rétention 30
# jours) — à adapter selon les objectifs RTO/RPO retenus par l'équipe
# (CDC section 17, "voir les risques, section 9").
resource "azurerm_backup_policy_vm" "daily" {
  name                = "bp-cyna-vm-daily"
  resource_group_name = azurerm_resource_group.cyna.name
  recovery_vault_name = azurerm_recovery_services_vault.cyna.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }
}
