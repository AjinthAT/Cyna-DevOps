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

- l'onboarding Azure Arc des serveurs Genève/Paris (agent installé machine par machine, pas un objet Terraform — voir `ansible/playbooks/onboard-azure-arc.yml`) ;
- le déploiement des VM elles-mêmes (hors périmètre Azure, cf. CDC section 4.2 « Périmètre exclu ») ;
- Shuffle (SOAR), qui reste hors dépôt (voir `docs/procedure-shuffle-glpi.md`).

## Statut

Ce module comble l'écart documenté dans le CDC (« Terraform : non encore implémenté dans le dépôt à la date de rédaction ») et dans le README principal (« Le dossier `terraform/` n'existe pas encore »). Il n'a **pas été appliqué sur un abonnement Azure réel** au moment de sa rédaction : à exécuter avec `terraform plan` avant tout `apply`, et à ajuster selon les retours de `terraform validate` (les APIs Azure Monitor évoluent vite ; le bloc `azurerm_monitor_diagnostic_setting` et le nom de métrique utilisé par `azurerm_monitor_metric_alert.backup_health` sont les points les plus susceptibles de nécessiter un ajustement selon la version exacte du provider résolue).

## Stratégie de tests

Le sujet CYNA cite explicitement des « tests unitaires » pour les scripts Terraform/Ansible. Deux familles d'outils existent pour ça : des frameworks de test dédiés (Terratest pour Terraform, Molecule pour Ansible — exécutent le code dans un environnement jetable et vérifient le résultat), ou une combinaison validation statique + test d'intégration réel (`terraform validate`/`fmt` et un déploiement réel testé en CI, cf. `.github/workflows/ci.yml`, jobs `terraform-validate` et `integration-test`).

Ce module retient la seconde approche, par choix assumé plutôt que par défaut :

- **Terratest nécessite un vrai `terraform apply`** (donc un abonnement Azure actif et des identifiants `ARM_*` en secrets CI) pour tester quoi que ce soit d'utile — un simple `terraform validate` ne suffit pas à Terratest, qui teste l'infrastructure réellement provisionnée. Ce module n'a pas d'identifiants Azure configurés en secrets du dépôt à ce stade du projet (cf. section « Statut ») : Terratest ne pourrait donc pas s'exécuter en CI sans cette étape préalable.
- Le hub Azure de ce module (Resource Group, VNet, Key Vault, Monitor, Backup, Storage) est un ensemble de ressources d'infrastructure plutôt qu'une logique applicative complexe : `terraform validate` (cohérence du schéma HCL et des types) et `terraform fmt -check` (style) couvrent l'essentiel des erreurs qu'on y rencontre en pratique (référence de variable incorrecte, bloc mal fermé, type invalide).
- Le job `integration-test` de la CI (voir `docs/architecture-cicd.md`) démontre déjà qu'un déploiement réel est testé bout en bout — pour la stack monitoring Docker Compose, avec les mêmes limites d'accès aux identifiants cloud que pour Terraform.

Si un abonnement Azure dédié aux tests CI devient disponible (via des secrets `ARM_*` sur le dépôt GitHub), Terratest reste l'évolution naturelle pour tester réellement les ressources provisionnées (ex. vérifier qu'un VNet a bien la plage d'adressage attendue) plutôt que seulement leur définition HCL — documenté ici comme évolution possible, pas comme prérequis non tenu.

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

Ce flux `terraform.tfvars` (non versionné, cf. `.gitignore`) reste utile pour une expérimentation rapide et personnelle. Pour toute utilisation avec plusieurs environnements distincts (dev / staging / démo finale), utiliser plutôt les fichiers `environments/*.tfvars.example` décrits ci-dessous.

## Multi-environnement

Le module est paramétré par environnement via `var.environment` (désormais réellement appliqué : voir `locals.tf`, qui l'ajoute au tag `environnement` de toutes les ressources) et un fichier `-var-file` dédié par environnement dans `environments/` :

| Environnement | Fichier modèle (versionné) | Resource Group | Usage |
|---|---|---|---|
| dev | `environments/dev.tfvars.example` | `RG-CYNA-DEV` | Tests individuels d'une évolution du module, rétention de logs réduite (7 jours) |
| staging | `environments/staging.tfvars.example` | `RG-CYNA-STAGING` | Validation avant application sur l'environnement de démo, mêmes réglages que prod |
| prod (démo/soutenance) | `environments/prod.tfvars.example` | `RG-CYNA-PROD` | Environnement présenté en soutenance |

Le `.gitignore` à la racine du dépôt exclut tous les `*.tfvars` (pas seulement `terraform.tfvars`) : ces fichiers sont donc fournis en `.example`, sur le même modèle que `terraform.tfvars.example`. Copier le fichier correspondant avant utilisation :

```bash
cp environments/dev.tfvars.example environments/dev.tfvars
```

`key_vault_name`, `storage_account_name`, `recovery_vault_name` et `log_analytics_workspace_name` sont différents dans chaque fichier (contrainte Azure : plusieurs de ces noms doivent être uniques au niveau mondial, et il ne faut pas que deux environnements pointent vers la même ressource).

Ce dépôt n'a pas de backend Terraform distant configuré (`versions.tf` ne déclare pas de bloc `backend`, cf. `.gitignore` qui exclut les `*.tfstate`) : chaque environnement doit donc utiliser un fichier d'état **séparé**, sans quoi `terraform apply` sur `dev` risquerait de modifier ou détruire les ressources `prod`. Deux options :

**Option 1 — état local séparé par environnement (le plus simple, adapté au contexte projet étudiant) :**

```bash
terraform init
terraform plan  -var-file=environments/dev.tfvars -state=environments/dev.tfstate
terraform apply -var-file=environments/dev.tfvars -state=environments/dev.tfstate

# puis, pour l'environnement de démo, avec un état totalement distinct :
terraform plan  -var-file=environments/prod.tfvars -state=environments/prod.tfstate
terraform apply -var-file=environments/prod.tfvars -state=environments/prod.tfstate
```

**Option 2 — backend distant (recommandé pour un usage au-delà du projet étudiant) :** configurer un backend `azurerm` (Storage Account dédié à l'état, hors du périmètre de ce module pour éviter une dépendance circulaire) avec une `key` différente par environnement, par exemple :

```hcl
# à ajouter dans versions.tf (valeurs indicatives, storage account à créer manuellement en amont)
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cyna-tfstate"
    storage_account_name = "stcynatfstate"
    container_name       = "tfstate"
    key                  = "cyna.tfstate" # dev.tfstate / staging.tfstate / prod.tfstate selon l'environnement
  }
}
```

## Rollback et journalisation

Le module ne fait aujourd'hui aucun `terraform apply` automatique (le job CI `terraform-validate`, voir `.github/workflows/ci.yml`, se limite à `fmt`/`init -backend=false`/`validate` — pas d'identifiants Azure en secrets du dépôt). Le rollback est donc, à ce stade, un processus manuel mais outillé et journalisé :

1. **Avant tout `apply`**, produire et conserver un plan nommé et daté :

   ```bash
   terraform plan -var-file=environments/prod.tfvars -state=environments/prod.tfstate -out=environments/plans/prod-$(date +%Y%m%d-%H%M).tfplan
   ```

   Le dossier `environments/plans/` n'est pas versionné (fichiers `*.tfplan` déjà exclus par `.gitignore`) : ces artefacts sont à archiver hors dépôt (ex. export vers le Storage Account `stcynaprojet`, conteneur `journaux`, créé par `storage.tf`) le temps de la démo, pour pouvoir rejouer exactement l'`apply` correspondant ou l'auditer a posteriori.

2. **Historique des changements de configuration** : chaque évolution du module passe par une Pull Request sur `feature/...` avant fusion dans `main` (historique Git = journal des changements d'infrastructure). `git log --oneline -- terraform/` donne la liste chronologique des évolutions du module.

3. **Rollback applicatif** : revenir à la configuration précédente avec `git revert` (ou `git checkout <commit précédent> -- terraform/`) puis rejouer `terraform plan`/`apply` avec cette configuration antérieure — Terraform ajuste alors l'infrastructure réelle pour qu'elle corresponde à nouveau à l'état du code, ce qui constitue le rollback (approche IaC : on ne restaure pas une sauvegarde d'infrastructure, on ré-applique une version antérieure de la définition).

4. **Rollback des données** (Key Vault, sauvegardes VM) : couvert par les mécanismes Azure natifs déjà activés dans ce module plutôt que par Terraform lui-même — `purge_soft_delete_on_destroy`/`recover_soft_deleted_key_vaults` (Key Vault, `versions.tf`) et la politique de sauvegarde quotidienne (`azurerm_backup_policy_vm`, `backup.tf`) permettent de restaurer une version antérieure des secrets ou des VM sauvegardées indépendamment d'un rollback Terraform.

5. **Journaux** : toutes les opérations de contrôle (création/modification/suppression de ressource, accès Key Vault) sont captées par le Log Analytics Workspace (`law-cyna-<env>`, `monitor.tf`) avec la rétention définie par `log_retention_days` — c'est la source à consulter en cas d'incident lié à un `apply`, en plus du fichier de plan archivé à l'étape 1.

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
