# Supervision et centralisation des logs cloud/hybrides.
# Cf. CDC section 16 : "Log Analytics Workspace" et "Azure Monitor".
#
# L'onboarding Azure Arc des serveurs Genève/Paris (agent Connected Machine)
# n'est pas un objet Terraform : il s'installe machine par machine via
# ansible/playbooks/onboard-azure-arc.yml (cf. docs/procedure-pra-pca.md,
# section "PRA des configurations IaC"). Ce fichier prépare seulement la
# destination (workspace + alerting) que les serveurs Arc et les ressources
# du hub enverront.

resource "azurerm_log_analytics_workspace" "cyna" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.cyna.location
  resource_group_name = azurerm_resource_group.cyna.name

  sku               = "PerGB2018"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "azurerm_monitor_action_group" "cyna_alerts" {
  name                = "ag-cyna-supervision"
  resource_group_name = azurerm_resource_group.cyna.name
  short_name          = "cyna-alert"

  email_receiver {
    name          = "referent-devops"
    email_address = "devops@cyna.example" # à remplacer par l'adresse réelle de l'équipe
  }

  tags = local.common_tags
}

# Exemple d'alerte : échec d'une sauvegarde dans le Recovery Services Vault
# (cf. CDC section 17, "Exigences de sauvegarde" et critères de recette 20.3).
resource "azurerm_monitor_metric_alert" "backup_health" {
  name                = "alert-cyna-backup-health"
  resource_group_name = azurerm_resource_group.cyna.name
  scopes              = [azurerm_recovery_services_vault.cyna.id]
  description         = "Se déclenche si un job de sauvegarde échoue dans le Recovery Services Vault CYNA."
  severity            = 1
  frequency           = "PT15M"
  window_size         = "PT1H"

  criteria {
    metric_namespace = "Microsoft.RecoveryServices/vaults"
    metric_name      = "BackupHealthEvent"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.cyna_alerts.id
  }

  tags = local.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-kv-cyna"
  target_resource_id         = azurerm_key_vault.cyna.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cyna.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }
}
