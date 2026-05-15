# Automatisation des incidents avec Shuffle et GLPI

## Objectif

Cette procédure décrit l’automatisation de la création de tickets GLPI à partir des alertes Prometheus/Alertmanager.

## Chaîne de traitement

Prometheus détecte une anomalie sur une cible supervisée.  
Alertmanager reçoit l’alerte et la transmet à un webhook Shuffle.  
Shuffle joue le rôle d’orchestrateur SOAR local.  
Il ouvre une session API GLPI puis crée automatiquement un ticket d’incident.

## Flux technique

Prometheus → Alertmanager → Shuffle → GLPI

## Intérêt DevOps

Cette automatisation réduit le délai de traitement des incidents, centralise le suivi dans GLPI et améliore la traçabilité des alertes de supervision.
