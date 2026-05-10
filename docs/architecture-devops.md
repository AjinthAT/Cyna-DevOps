# Architecture DevOps — CYNA

## Objectif

La partie DevOps du projet CYNA vise à automatiser le déploiement, la supervision, l'alerting et la gestion des incidents de l'infrastructure.

## Composants utilisés

| Composant | Rôle |
|---|---|
| GitHub | Versionnement du code, des configurations et de la documentation |
| Docker Compose | Déploiement de la stack de supervision |
| Prometheus | Collecte des métriques |
| Grafana | Visualisation des métriques via dashboards |
| Alertmanager | Gestion et routage des alertes |
| Node Exporter | Exposition des métriques système Linux |
| Blackbox Exporter | Tests de disponibilité HTTP |
| Incident Webhook | Simulation d'un outil SOAR ou ServiceNow |

## Chaîne de supervision

Prometheus collecte les métriques depuis les exporters.

Lorsqu'une anomalie est détectée, Prometheus déclenche une alerte.

Alertmanager reçoit cette alerte et la transmet au webhook d'incident.

Le webhook enregistre l'incident dans un fichier JSON consultable via API.

## Schéma logique

    GitHub
       |
       v
    Repository DevOps
       |
       v
    Docker Compose
       |
       v
    Prometheus ----> Grafana
       |
       v
    Alertmanager
       |
       v
    Incident Webhook
       |
       v
    incidents.json

## Évolutions prévues

Dans la maquette finale, la stack DevOps pourra superviser :

- le serveur GNS3 ;
- les VMs Linux ;
- la VM Web / SaaS ;
- les services SIEM / SOC ;
- les services d'administration ;
- les équipements exposant des métriques ou des ports testables.
