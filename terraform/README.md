# Terraform — Hub Azure CYNA

## Objectif

Ce module provisionne le hub Azure décrit dans le cahier des charges (section 16 « Cloud hybride Azure » et section 10.4 « Azure Hub ») :

- Resource Group `RG-CYNA-PROD` ;
- VNet `VNET-CYNA-HUB` (10.30.0.0/16) et ses sous-réseaux `GatewaySubnet`, `SNET-MGMT`, `SNET-SECURITY`, `SNET-BACKUP`, `SNET-PRA` ;
- Azure VPN Gateway + Local Network Gateways (Genève/Paris) — **désactivés par défaut**, voir plus bas ;
- Log Analytics Workspace + Action Group + une alerte d'exemple (échec de sauvegarde) ;
- Key Vault ;
- Recovery Services Vault + une politique de sauvegarde VM quotidienne ;
- Storage Account (conteneurs `exports` et `journaux`).

Ce que ce module ne fait **pas** :

- l'onboarding Azure Arc des serveurs Genève/Paris (agent installé machine par machine, pas un objet Terraform) ;
- le déploiement des VM elles-mêmes (hors périmètre Azure, cf. CDC section 4.2 « Périmètre exclu ») ;
- Shuffle (SOAR), qui reste hors dépôt (voir `docs/procedure-shuffle-glpi.md`).

## Statut

Ce module comble l'écart documenté dans le CDC (« Terraform : non encore implémenté dans le dépôt à la date de rédaction ») et dans le README principal (« Le dossier `terraform/` n'existe pas encore »). Il n'a **pas été appliqué sur un abonnement Azure réel** au moment de sa rédaction : à exécuter avec `terraform plan` avant tout `apply`, et à ajuster selon les retours de `terraform validate` (les APIs Azure Monitor évoluent vite ; le bloc `azurerm_monitor_diagnostic_setting` et le nom de métrique utilisé par `azurerm_monitor_metric_alert.backup_health` sont les points les plus susceptibles de nécessiter un ajustement selon la version exacte du provider résolue).

## Prérequis

- Un abonnement Azure (abonnement étudiant Azure for Students dans le cadre du projet) ;
- Terraform ≥ 1.6 ;
- Être authentifié (`az login`, ou variables d'environnement `ARM_*` pour un service principal).

## Utilisation

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# éditer terraform.tfvars : key_vault_name et storage_account_name doivent être uniques
# au niveau mondial sur Azure — les valeurs par défaut échoueront probablement telles quelles.

terraform init
terraform validate
terraform plan
terraform apply
```

## Activer le VPN site-à-site

`enable_vpn_gateway` est à `false` par défaut : l'Azure VPN Gateway est facturé à l'heure même à l'arrêt (SKU `VpnGw1` ≈ plusieurs dizaines d'euros par mois), et le CDC (section 9, risques) documente déjà que ce lien peut être bloqué par le NAT de l'environnement GNS3, avec un repli sur Azure Arc/Monitor en HTTPS. Ne l'activer que si le tunnel IPsec a réellement besoin d'être démontré :

```hcl
enable_vpn_gateway = true
```

Il faudra alors renseigner les vraies IP publiques de sortie de FW-GE-01 et FW-PAR-01 dans `on_prem_gateways` (variables.tf), ainsi qu'une vraie clé partagée (`shared_key` dans `network.tf`, actuellement une valeur factice à remplacer — idéalement via une variable sensible ou le Key Vault plutôt qu'en dur).

## Coûts (abonnement étudiant)

Avec `enable_vpn_gateway = false`, les ressources qui restent (Resource Group, VNet, Key Vault, Log Analytics, Recovery Services Vault, Storage Account) ont un coût proche de zéro tant qu'elles ne sont pas utilisées activement (facturation à la consommation : ingestion de logs, opérations de sauvegarde, stockage). Le VPN Gateway est de loin le poste le plus coûteux du module — d'où le fait qu'il soit désactivé par défaut.

## Détruire l'environnement

```bash
terraform destroy
```

`purge_soft_delete_on_destroy` (Key Vault) et `purge_protected_items_from_vault_on_destroy` (Recovery Services Vault) sont activés dans `versions.tf` pour permettre un destroy complet en contexte de projet étudiant — à retirer avant tout usage réel où la protection contre la suppression accidentelle est souhaitée.
