# PRA / PCA — Partie DevOps CYNA

## Objectif

Assurer la restauration rapide de la stack DevOps en cas de panne, corruption de configuration ou perte de la VM.

Ce document couvre deux volets distincts :

- la stack DevOps elle-même (monitoring, GLPI) — voir « Éléments sauvegardés » ci-dessous ;
- les configurations Infrastructure as Code (Terraform, Ansible) — voir « PRA des configurations IaC », qui répond spécifiquement au sujet CYNA (Répartition des tâches, DEVOPS : « Infrastructure as Code (IaC) : automatiser le déploiement des infrastructures avec Terraform et Ansible, intégrer un PRA pour restauration rapide des configurations IaC en cas de défaillance »).

## Éléments sauvegardés

Les éléments suivants doivent être sauvegardés :

- repository Git ;
- fichiers Docker Compose ;
- configurations Prometheus ;
- règles d'alerting ;
- configuration Alertmanager ;
- export du workflow Shuffle (`shuffle/workflows/`) ;
- base GLPI (dump SQL) ;
- scripts de déploiement ;
- documentation technique.

Non couvert par cette sauvegarde : l'installation Shuffle elle-même (hors repository, voir `procedure-shuffle-glpi.md`) et les fichiers joints GLPI (`glpi_data`, pertinent uniquement si des tickets réels ont des pièces jointes).

## Sauvegarde

Depuis la racine du repository :

    ./scripts/backup-devops.sh

Deux fichiers sont produits dans `~/cyna-backups` :

- `cyna-devops-<date>.tar.gz` — code et configuration du repository ;
- `cyna-glpi-db-<date>.sql.gz` — dump de la base GLPI (ignoré si `cyna-glpi-db` n'est pas démarré).

## Restauration

Étapes de restauration :

1. recréer une VM Ubuntu Server propre ;
2. installer Git, Docker, Docker Compose et Ansible ;
3. cloner le repository ;
4. relancer la stack de supervision.

Commandes (redéploiement depuis Git, sans restauration des données GLPI) :

    git clone https://github.com/AjinthAT/Cyna-DevOps.git
    cd Cyna-DevOps/monitoring
    docker compose up -d --build

Pour restaurer aussi les tickets GLPI depuis une sauvegarde locale :

    ./scripts/restore-devops.sh ~/cyna-backups/cyna-devops-<date>.tar.gz ~/cyna-backups/cyna-glpi-db-<date>.sql.gz

## Objectifs de reprise

| Élément | Objectif |
|---|---|
| RTO | Moins de 30 minutes |
| RPO | Dernier commit Git et dernier dump GLPI |
| Méthode | Redéploiement depuis Git et Docker Compose, restauration SQL pour GLPI |

## Test PRA

Pour tester le PRA :

1. arrêter la stack ;
2. supprimer les conteneurs ;
3. relancer le déploiement depuis Git (`./scripts/restore-devops.sh`) ;
4. vérifier les interfaces Prometheus, Grafana et Alertmanager ;
5. vérifier que les tickets GLPI antérieurs à la sauvegarde sont bien présents.

## PRA des configurations IaC

Approche IaC classique : on ne restaure pas une sauvegarde d'infrastructure, on
réapplique une définition versionnée dans Git. Le RPO est donc borné par le
dernier commit, pas par une fenêtre de sauvegarde périodique.

### Terraform (hub Azure)

Couvert en détail dans `terraform/README.md`, section « Rollback et
journalisation » : plans nommés et datés conservés avant chaque `apply`,
historique Git comme journal des changements, `git revert` +
`terraform plan`/`apply` pour revenir à une configuration antérieure. Les
données (Key Vault, sauvegardes VM) sont couvertes séparément par les
mécanismes natifs Azure (`purge_soft_delete_on_destroy`,
`azurerm_backup_policy_vm`) déjà activés dans le module.

Reconstruction complète depuis zéro (perte totale du hub Azure) :

    cd terraform
    terraform init
    terraform apply -var-file=environments/prod.tfvars -state=environments/prod.tfstate

### Ansible (matrice firewall, monitoring, Azure Arc)

- **Matrice de flux Zero Trust** : la source de vérité est le fichier
  `ansible/playbooks/vars/firewall-zero-trust-<site>.yml`, versionné dans
  Git. En cas de configuration Sophos corrompue ou de remplacement de
  boîtier, rejouer `ansible-playbook ansible/playbooks/deploy-firewall-rules.yml`
  recrée l'intégralité des règles avec vérification automatique
  (voir `procedure-firewall-automation.md`). Un export daté de la
  configuration effectivement appliquée est en plus produit par
  `ansible/playbooks/backup-firewall-config.yml`, à archiver hors du
  firewall lui-même (ex. Storage Account `stcynaprojet`, conteneur
  `journaux`, cf. `terraform/README.md`) pour pouvoir comparer un état
  antérieur en cas de doute sur une modification faite hors playbook.
- **Stack de supervision et Node Exporter** : `deploy-monitoring.yml` et
  `deploy-node-exporter.yml` sont idempotents et rejouables tels quels pour
  reconstruire une machine depuis zéro.
- **Azure Arc** : `onboard-azure-arc.yml` réenregistre une machine dans le
  Log Analytics Workspace du hub après réinstallation.

### Objectifs de reprise — IaC

| Élément | Objectif |
|---|---|
| RTO | Le temps d'un `terraform apply` / `ansible-playbook` (quelques minutes), hors provisionnement Azure lui-même |
| RPO | Dernier commit Git sur `terraform/` ou `ansible/` |
| Méthode | Réapplication de la configuration versionnée, pas de restauration de sauvegarde d'infrastructure |

### Test

Pour valider que la restauration IaC fonctionne sans divergence :

1. `terraform plan` sur un environnement existant doit renvoyer *no changes*
   (la configuration versionnée correspond à l'infrastructure réelle) ;
2. rejouer `deploy-firewall-rules.yml` doit rester idempotent : aucune règle
   dupliquée, le test de validation intégré au playbook doit passer sans
   modification apparente pour les règles déjà conformes.
