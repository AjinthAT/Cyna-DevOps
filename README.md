# CYNA — Partie DevOps

## Objectif

Ce repository contient la partie DevOps du projet CYNA.

Il couvre :

- automatisation ;
- supervision ;
- alerting ;
- gestion des incidents (Shuffle + GLPI) ;
- préparation PRA/PCA ;
- documentation technique.

## Stack utilisée

- Git / GitHub ;
- Ansible ;
- Docker Compose ;
- Prometheus ;
- Grafana ;
- Alertmanager ;
- Node Exporter ;
- Blackbox Exporter ;
- Shuffle (orchestrateur SOAR, hébergé à part) ;
- GLPI + MariaDB (gestion des tickets ITSM) ;
- Terraform (hub Azure : Resource Group, VNet, Key Vault, Log Analytics/Monitor, Recovery Services Vault, Storage Account).

## Structure du repository

    ansible/              Playbooks Ansible
    monitoring/           Stack Prometheus / Grafana / Alertmanager / GLPI
    shuffle/workflows/    Exports des workflows Shuffle (SOAR)
    terraform/            Hub Azure (Resource Group, VNet, Key Vault, Monitor, Backup, Storage)
    scripts/              Scripts de déploiement, sauvegarde et tests
    docs/                 Documentation technique
    .env.example          Modèle de variables d'environnement (accès GLPI)

Le hub Azure (Resource Group, VNet, Key Vault, Monitor, Backup) est provisionné par le module dans `terraform/` — voir `terraform/README.md` pour l'utilisation, le statut (non encore appliqué sur un abonnement réel) et le coût. Le VPN site-à-site Azure y est désactivé par défaut (coût horaire, cf. `terraform/variables.tf`).

Shuffle lui-même n'est pas déployé depuis ce repository (installation Docker Swarm séparée sur la VM) : seul l'export de son workflow est versionné ici. Voir `docs/procedure-shuffle-glpi.md`.

## Déploiement rapide

Depuis la racine du repository :

    cd monitoring
    docker compose up -d --build

Cette commande déploie également GLPI et sa base MariaDB.

Pour les scripts qui interrogent l'API GLPI, copier `.env.example` en `.env.local` et renseigner `GLPI_URL`, `GLPI_APP_TOKEN` et `GLPI_USER_TOKEN`.

## Interfaces

| Service | Port |
|---|---:|
| Prometheus | 9090 |
| Grafana | 3000 |
| Alertmanager | 9093 |
| Node Exporter | 9100 |
| Blackbox Exporter | 9115 |
| GLPI | 8080 |

## Chaîne d'alerting et gestion des incidents

Le flux d'automatisation actif est :

    Prometheus → Alertmanager → Shuffle (SOAR) → GLPI (ticket)

Alertmanager (`monitoring/alertmanager/alertmanager.yml`) route toutes les alertes vers un webhook Shuffle externe. Shuffle ouvre une session sur l'API GLPI et crée automatiquement le ticket d'incident correspondant. Le détail de cette chaîne est décrit dans `docs/procedure-shuffle-glpi.md`.

## Test d'alerte

Arrêter Node Exporter :

    docker stop cyna-node-exporter

Attendre environ 90 secondes, puis vérifier :

- Prometheus > Alerts ;
- l'apparition d'un ticket dans GLPI (Assistance > Tickets).

Relancer Node Exporter :

    docker start cyna-node-exporter

Tester la création d'un ticket GLPI sans attendre une alerte réelle :

    ./scripts/test-glpi-ticket.sh

## Vérification des services

    ./scripts/check-services.sh

## Documentation

La documentation détaillée est disponible dans `docs/` :

- `architecture-devops.md` — vue d'ensemble de la chaîne DevOps ;
- `procedure-deploiement.md` — prérequis et déploiement de la stack ;
- `procedure-supervision.md` — supervision Prometheus / Grafana ;
- `procedure-shuffle-glpi.md` — automatisation des tickets GLPI via Shuffle ;
- `procedure-pra-pca.md` — sauvegarde et restauration de la stack DevOps ;
- `integration-groupe.md` — intégration avec les autres périmètres du projet CYNA.
