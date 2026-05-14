# Procédure de gestion des incidents DevOps

## Objectif

Cette procédure décrit la manière dont les alertes de supervision sont transformées en incidents exploitables.

## Chaîne d'alerting

Prometheus détecte une anomalie, puis transmet l'alerte à Alertmanager. Alertmanager envoie ensuite l'alerte au webhook Flask, qui crée un incident consultable via API.

```text
Prometheus → Alertmanager → Webhook Flask → incidents.json
