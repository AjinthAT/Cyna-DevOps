# Procédure de gestion des incidents DevOps

## Objectif

Cette procédure décrit le fonctionnement de la gestion automatisée des incidents dans la stack DevOps CYNA.

Les alertes générées par Prometheus sont transmises à Alertmanager, puis envoyées au webhook d’incidents CYNA.

## Chaîne de traitement

```text
Prometheus → Alertmanager → Incident Webhook → incidents.json
