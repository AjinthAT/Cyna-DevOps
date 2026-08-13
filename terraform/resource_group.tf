# Regroupement logique de toutes les ressources du hub Azure CYNA.
# Cf. CDC section 16 "Cloud hybride Azure", tableau des ressources Azure : RG-CYNA-PROD.

resource "azurerm_resource_group" "cyna" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
