# Architecture DevOps — CYNA

## Objectif

La partie DevOps du projet CYNA vise à automatiser le déploiement, la supervision, l'alerting et la gestion des incidents de l'infrastructure. Liste des composants et de leur rôle : voir `../README.md`, section « Stack utilisée ». Ce document se concentre sur la chaîne de supervision elle-même et son périmètre.

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

## Périmètre de supervision

Déjà couvert par `monitoring/prometheus/prometheus.yml` (voir
`procedure-supervision.md` pour le détail par machine) : les VM Linux de
l'infra Genève (SAAS-GE-01, APP-BACKEND-01, WAZUH-GE-01, BACKUP-GE-01), la
disponibilité HTTP(S) de la plateforme SaaS et du dashboard Wazuh
(SIEM/SOC), et les services internes de la VM DevOps elle-même.

Pas encore couvert : le serveur GNS3 lui-même (l'hôte qui exécute la
maquette, distinct des VM qu'il héberge), les services d'administration
Windows (AD-GE-01/02, FILE-GE-01 — nécessite `windows_exporter`, aucun
playbook WinRM fourni à ce stade) et les équipements réseau (Sophos,
switches) au-delà de leurs logs déjà remontés au SIEM.
