# Hub réseau Azure. Cf. CDC section 10.4 "Azure Hub" et section 16 "Cloud hybride Azure".
#
# VNET-CYNA-HUB (10.30.0.0/16) porte les sous-réseaux GatewaySubnet, SNET-MGMT,
# SNET-SECURITY, SNET-BACKUP et SNET-PRA décrits dans le CDC.

resource "azurerm_virtual_network" "hub" {
  name                = var.vnet_name
  location            = azurerm_resource_group.cyna.location
  resource_group_name = azurerm_resource_group.cyna.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.cyna.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes
}

# ---------------------------------------------------------------------------
# VPN site-à-site (Genève / Paris) — désactivé par défaut, voir variables.tf.
# Le CDC (section 9, risques) documente déjà le repli sur Azure Arc/Monitor en
# HTTPS si le NAT de l'environnement GNS3 bloque le tunnel IPsec.
# ---------------------------------------------------------------------------

resource "azurerm_public_ip" "vpn_gateway" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "pip-vpngw-cyna"
  location            = azurerm_resource_group.cyna.location
  resource_group_name = azurerm_resource_group.cyna.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "hub" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "vpngw-cyna-hub"
  location            = azurerm_resource_group.cyna.location
  resource_group_name = azurerm_resource_group.cyna.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  # SKU d'entrée de gamme : suffisant pour la démonstration, à revoir si un
  # vrai déploiement multi-tunnels est envisagé.
  sku = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
  }

  tags = var.tags
}

resource "azurerm_local_network_gateway" "site" {
  for_each = var.enable_vpn_gateway ? var.on_prem_gateways : {}

  name                = each.key
  location            = azurerm_resource_group.cyna.location
  resource_group_name = azurerm_resource_group.cyna.name
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "site" {
  for_each = var.enable_vpn_gateway ? var.on_prem_gateways : {}

  name                            = "cnx-${each.key}"
  location                        = azurerm_resource_group.cyna.location
  resource_group_name             = azurerm_resource_group.cyna.name
  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub[0].id
  local_network_gateway_id        = azurerm_local_network_gateway.site[each.key].id
  shared_key                      = "changez-moi-avant-apply" # à remplacer par un secret réel (cf. Key Vault)
  tags                            = var.tags
}
