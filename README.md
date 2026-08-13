# CYNA — Partie DevOps

## Objectif

Ce repository contient la partie DevOps du projet CYNA.

Il couvre :

- automatisation (déploiement, règles firewall Zero Trust) ;
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
- Terraform (hub Azure : Resource Group, VNet, Key Vault, Log Analytics/Monitor, Recovery Services Vault, Storage Account) ;
- Helm (déploiement et autoscaling de l'application SaaS sur le cluster k3s de SAAS-GE-01) ;
- GitHub Actions (intégration continue : validation, test d'intégration, `terraform validate`, `helm lint`) ;
- Sophos XGS (règles firewall Zero Trust pilotées par Ansible via l'API du firewall).

## Structure du repository

    ansible/              Playbooks Ansible (supervision, firewall Zero Trust — voir ansible/README.md)
    monitoring/           Stack Prometheus / Grafana / Alertmanager / GLPI
    shuffle/workflows/    Exports des workflows Shuffle (SOAR)
    terraform/            Hub Azure (Resource Group, VNet, Key Vault, Monitor, Backup, Storage)
                            + environments/ (dev, staging, prod)
    helm/saas-app/        Chart Helm pour l'application SaaS (cluster k3s, SAAS-GE-01)
    scripts/              Scripts de déploiement, sauvegarde et tests
    docs/                 Documentation technique
    .github/workflows/    Pipeline CI/CD (GitHub Actions)
    .env.example          Modèle de variables d'environnement (accès GLPI)

Le hub Azure (Resource Group, VNet, Key Vault, Monitor, Backup) est provisionné par le module dans `terraform/` — voir `terraform/README.md` pour l'utilisation, le multi-environnement, le statut (non encore appliqué sur un abonnement réel) et le coût. Le VPN site-à-site Azure y est désactivé par défaut (coût horaire, cf. `terraform/variables.tf`).

Le chart Helm dans `helm/saas-app/` déploie l'application front-end SaaS sur le cluster k3s de `SAAS-GE-01` avec scaling automatique (HPA) — voir `helm/saas-app/README.md` pour l'utilisation et ses limites assumées (image applicative de substitution tant que l'image réelle n'est pas publiée).

Les playbooks Ansible et la stratégie de tests retenue (validation + intégration plutôt que Molecule) sont détaillés dans `ansible/README.md`.

Le pipeline CI/CD (`.github/workflows/ci.yml`) est détaillé, avec un diagramme de flux, dans `docs/architecture-cicd.md`.

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
- `architecture-cicd.md` — pipeline CI/CD GitHub Actions, avec diagramme de flux ;
- `procedure-deploiement.md` — prérequis et déploiement de la stack ;
- `procedure-supervision.md` — supervision Prometheus / Grafana ;
- `procedure-shuffle-glpi.md` — automatisation des tickets GLPI via Shuffle ;
- `procedure-firewall-automation.md` — matrice de flux Zero Trust et automatisation des règles Sophos via Ansible ;
- `procedure-pra-pca.md` — sauvegarde et restauration de la stack DevOps ;
- `integration-groupe.md` — intégration avec les autres périmètres du projet CYNA.
