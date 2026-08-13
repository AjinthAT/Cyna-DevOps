variable "location" {
  description = "Région Azure où déployer les ressources (abonnement étudiant : privilégier une région autorisée par le quota, ex. francecentral ou westeurope)."
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Nom du groupe de ressources regroupant l'ensemble du hub Azure CYNA (cf. CDC section 16, tableau des ressources Azure)."
  type        = string
  default     = "RG-CYNA-PROD"
}

variable "environment" {
  description = "Étiquette d'environnement appliquée à toutes les ressources (tag)."
  type        = string
  default     = "projet-fil-rouge"
}

variable "vnet_name" {
  description = "Nom du VNet hub (cf. CDC section 10.4 / 16 : VNET-CYNA-HUB, 10.30.0.0/16)."
  type        = string
  default     = "VNET-CYNA-HUB"
}

variable "vnet_address_space" {
  description = "Plage d'adressage du VNet hub Azure, cohérente avec le plan d'adressage global (10.10.0.0/16 Genève, 10.20.0.0/16 Paris, 10.30.0.0/16 Azure)."
  type        = list(string)
  default     = ["10.30.0.0/16"]
}

variable "subnets" {
  description = "Sous-réseaux du hub Azure, repris du tableau de la section 10.4 du CDC (GatewaySubnet, SNET-MGMT, SNET-SECURITY, SNET-BACKUP, SNET-PRA)."
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    "GatewaySubnet" = { address_prefixes = ["10.30.0.0/27"] } # nom imposé par Azure pour le VPN Gateway
    "SNET-MGMT"     = { address_prefixes = ["10.30.1.0/24"] }
    "SNET-SECURITY" = { address_prefixes = ["10.30.2.0/24"] }
    "SNET-BACKUP"   = { address_prefixes = ["10.30.3.0/24"] }
    "SNET-PRA"      = { address_prefixes = ["10.30.4.0/24"] }
  }
}

variable "enable_vpn_gateway" {
  description = <<-EOT
    Active la création de l'Azure VPN Gateway et des Local Network Gateways (Genève/Paris).
    Laissé à `false` par défaut : ces ressources sont facturées à l'heure même à l'arrêt
    (VpnGw1 ≈ plusieurs dizaines d'euros/mois) et le CDC (section 9, risques) documente déjà
    que le lien site-à-site peut être bloqué par le NAT de l'environnement GNS3, auquel cas
    la démonstration se fait via Azure Arc/Monitor en HTTPS.
  EOT
  type        = bool
  default     = false
}

variable "on_prem_gateways" {
  description = "Passerelles locales à déclarer côté Azure si enable_vpn_gateway = true (cf. CDC section 10.1, tableau WAN)."
  type = map(object({
    gateway_address = string
    address_space   = list(string)
  }))
  default = {
    "LNG-GENEVE" = {
      gateway_address = "203.0.113.1" # IP publique factice : à remplacer par l'IP réelle du FW-GE-01 en sortie Internet
      address_space   = ["10.10.0.0/16"]
    }
    "LNG-PARIS" = {
      gateway_address = "203.0.113.2" # IP publique factice : à remplacer par l'IP réelle du FW-PAR-01 en sortie Internet
      address_space   = ["10.20.0.0/16"]
    }
  }
}

variable "key_vault_name" {
  description = "Nom du Key Vault (doit être globalement unique sur Azure : personnaliser avant apply, ex. kv-cyna-<suffixe>)."
  type        = string
  default     = "kv-cyna-projet"
}

variable "log_analytics_workspace_name" {
  description = "Nom du Log Analytics Workspace centralisant les logs cloud et hybrides (cf. CDC section 16)."
  type        = string
  default     = "law-cyna-prod"
}

variable "log_retention_days" {
  description = "Durée de rétention des logs dans Log Analytics. 30 jours suffit pour la maquette et limite le coût sur l'abonnement étudiant."
  type        = number
  default     = 30
}

variable "recovery_vault_name" {
  description = "Nom du Recovery Services Vault (sauvegarde/restauration cloud, cf. CDC section 17)."
  type        = string
  default     = "rsv-cyna-prod"
}

variable "storage_account_name" {
  description = "Nom du Storage Account (artefacts, exports, journaux). Doit être unique globalement, 3-24 caractères minuscules/chiffres."
  type        = string
  default     = "stcynaprojet"
}

variable "tags" {
  description = "Tags communs appliqués à toutes les ressources."
  type        = map(string)
  default = {
    projet    = "CYNA"
    formation = "Projet Fil Rouge B3 - SUP DE VINCI"
    gere_par  = "terraform"
  }
}
