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
- code du webhook incident ;
- scripts de déploiement ;
- documentation technique.

## Sauvegarde

Depuis la racine du repository :

    ./scripts/backup-devops.sh

Les sauvegardes sont stockées dans :

    ~/cyna-backups

## Restauration

Étapes de restauration :

1. recréer une VM Ubuntu Server propre ;
2. installer Git, Docker, Docker Compose et Ansible ;
3. cloner le repository ;
4. relancer la stack de supervision.

Commandes :

    git clone https://github.com/AjinthAT/Cyna-DevOps.git
    cd Cyna-DevOps/monitoring
    docker compose up -d --build

## Objectifs de reprise

| Élément | Objectif |
|---|---|
| RTO | Moins de 30 minutes |
| RPO | Dernier commit Git et dernière sauvegarde locale |
| Méthode | Redéploiement depuis Git et Docker Compose |

## Test PRA

Pour tester le PRA :

1. arrêter la stack ;
2. supprimer les conteneurs ;
3. relancer le déploiement depuis Git ;
4. vérifier les interfaces Prometheus, Grafana et Alertmanager.
