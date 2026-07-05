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

## Déploiement de Shuffle

⚠️ Contrairement au reste de la stack (`monitoring/docker-compose.yml`), **Shuffle n'est pas déployé depuis ce repository**. L'installation vit dans `/home/administrateur/shuffle-soar/` sur la VM DevOps, sous forme d'une pile Docker Swarm (`shuffle-frontend`, `shuffle-backend`, `shuffle-opensearch`, `shuffle-orborus`, plus les workers `shuffle-tools`/`shuffle-ai`/`shuffle-subflow`).

Conséquence pour la reproductibilité (PRA/PCA) : reconstruire la VM ne suffit pas à retrouver Shuffle. Il faut réinstaller la stack Shuffle manuellement (voir la documentation officielle Shuffle) avant de pouvoir réimporter le workflow ci-dessous. C'est un écart connu par rapport à l'objectif « tout reproductible depuis Git », au même titre que l'absence de Terraform pour Azure.

## Export du workflow

Le workflow Shuffle utilisé pour cette automatisation est versionné dans :

    shuffle/workflows/alertmanager-vers-glpi.json

Pour le réimporter dans une instance Shuffle (existante ou reconstruite) :

1. Ouvrir Shuffle → Workflows → Import.
2. Sélectionner `shuffle/workflows/alertmanager-vers-glpi.json`.
3. Reconfigurer l'authentification GLPI dans le nœud "GLPI - Init Session" (l'export ne contient aucun identifiant, ils doivent être ressaisis après import).
4. Démarrer le workflow ("Start"), puis vérifier que son ID de webhook correspond à celui déclaré dans `monitoring/alertmanager/alertmanager.yml`. S'il diffère, mettre à jour l'URL du receiver `shuffle-webhook` dans ce fichier.
