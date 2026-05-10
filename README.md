# CYNA — Partie DevOps

## Objectif

Ce repository contient la partie DevOps du projet CYNA.

Il couvre :

- automatisation ;
- supervision ;
- alerting ;
- gestion d'incidents ;
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
- Incident Webhook ;
- Terraform / OpenTofu à venir.

## Structure du repository

    ansible/              Playbooks Ansible
    monitoring/           Stack Prometheus / Grafana / Alertmanager
    incident-webhook/     Webhook de simulation SOAR / ServiceNow
    scripts/              Scripts de déploiement et de sauvegarde
    terraform/            Infrastructure as Code
    docs/                 Documentation technique

## Déploiement rapide

Depuis la racine du repository :

    cd monitoring
    docker compose up -d --build

## Interfaces

| Service | Port |
|---|---:|
| Prometheus | 9090 |
| Grafana | 3000 |
| Alertmanager | 9093 |
| Incident Webhook | 5000 |
| Node Exporter | 9100 |
| Blackbox Exporter | 9115 |

## Test d'alerte

Arrêter Node Exporter :

    docker stop cyna-node-exporter

Attendre environ 90 secondes puis consulter :

    http://IP_VM:5000/incidents

Relancer Node Exporter :

    docker start cyna-node-exporter

## Documentation

La documentation est disponible dans le dossier docs/.
