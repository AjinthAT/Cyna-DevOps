# Intégration avec les autres périmètres CYNA

## Objectif

La stack DevOps est conçue pour être intégrée progressivement avec les composants réalisés par les autres étudiants.

## Informations nécessaires par composant

| Composant | Responsable | Informations attendues |
|---|---|---|
| GNS3 Server | Infrastructure | IP, port, accès SSH |
| VM Web / SaaS | Infrastructure / DevOps | IP, ports HTTP/HTTPS, accès SSH |
| SIEM / SOC | Cybersécurité | IP, ports services, logs disponibles |
| AD / DNS | Administration | IP, OS, ports à superviser |
| Stockage / fichiers | Administration | IP, protocole, métriques disponibles |

## Futures intégrations

### GNS3 Server

Installation de Node Exporter puis ajout dans Prometheus :

    - job_name: "gns3-server"
      static_configs:
        - targets:
            - "IP_GNS3:9100"

### VM Web / SaaS

Supervision prévue :

- métriques système via Node Exporter ;
- disponibilité HTTP via Blackbox Exporter ;
- alerte si le service Web ne répond plus.

### SIEM / SOC

Supervision prévue :

- disponibilité du service SIEM ;
- état des ports nécessaires ;
- intégration possible des alertes vers Splunk SOAR.

### ServiceNow / Splunk SOAR

Le webhook actuel simule un outil d'automatisation d'incident.

En production, il pourrait être remplacé par :

- API ServiceNow ;
- Splunk SOAR ;
- Microsoft Teams webhook ;
- Slack webhook.

## Principe d'intégration

La stack DevOps ne modifie pas directement les composants des autres étudiants tant que l'infrastructure n'est pas stabilisée.

Une fois les IP et services figés, les composants seront ajoutés dans :

- ansible/inventory.ini ;
- monitoring/prometheus/prometheus.yml ;
- monitoring/prometheus/alert-rules.yml.
