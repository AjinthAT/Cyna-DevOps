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
| Shuffle | Orchestrateur SOAR, déclenche la création de tickets |
| GLPI | Gestion des tickets d'incident (ITSM) |

## Chaîne de supervision

Prometheus collecte les métriques depuis les exporters.

Lorsqu'une anomalie est détectée, Prometheus déclenche une alerte.

Alertmanager reçoit cette alerte et la transmet à un webhook Shuffle.

Shuffle ouvre une session sur l'API GLPI et crée automatiquement le ticket d'incident correspondant (voir `procedure-shuffle-glpi.md`).

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
    Shuffle (SOAR)
       |
       v
    GLPI (ticket)

## Évolutions prévues

Dans la maquette finale, la stack DevOps pourra superviser :

- le serveur GNS3 ;
- les VMs Linux ;
- la VM Web / SaaS ;
- les services SIEM / SOC ;
- les services d'administration ;
- les équipements exposant des métriques ou des ports testables.
