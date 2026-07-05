# PRA / PCA — Partie DevOps CYNA

## Objectif

Assurer la restauration rapide de la stack DevOps en cas de panne, corruption de configuration ou perte de la VM.

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
