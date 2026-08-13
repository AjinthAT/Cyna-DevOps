# Ansible — CYNA DevOps

## Playbooks

| Playbook | Cible | Rôle |
|---|---|---|
| `playbooks/check-linux.yml` | `[linux]` | Contrôle de base des machines Linux |
| `playbooks/deploy-monitoring.yml` | `[devops]` | Déploiement de la stack de supervision (Docker Compose) + tests de validation post-déploiement |
| `playbooks/deploy-node-exporter.yml` | `[infra_linux]` | Installation de Node Exporter sur l'infra Genève + test de validation `/metrics` |
| `playbooks/deploy-firewall-rules.yml` | `[firewalls]` | Application de la matrice de flux Zero Trust sur les firewalls Sophos (voir `../docs/procedure-firewall-automation.md`) |

Groupes d'inventaire : voir `inventory.ini`. `[infra_windows]` (AD, fichiers) n'est pas couvert par des playbooks à ce stade (nécessite WinRM, non configuré).

## Stratégie de tests

Le sujet CYNA cite explicitement des « tests unitaires » pour les scripts Ansible, en plus des tests d'intégration/validation. Deux approches existent : un framework de test dédié (Molecule — exécute un rôle Ansible dans un conteneur/VM jetable et vérifie l'état obtenu), ou une combinaison contrôle de syntaxe + tests de validation `uri` après un déploiement réel (l'approche retenue ici, cf. `.github/workflows/ci.yml` et les tâches de validation dans `deploy-monitoring.yml`/`deploy-node-exporter.yml`).

Ce choix est assumé plutôt que par défaut :

- Molecule est pensé pour tester des **rôles** Ansible réutilisables (structure `roles/<nom>/`) de façon isolée. Ce dépôt utilise des **playbooks** directs plutôt que des rôles (plus simple pour la taille du projet — une dizaine de tâches par playbook, pas de logique à réutiliser entre plusieurs contextes) : découper en rôles uniquement pour pouvoir les tester avec Molecule aurait ajouté de la complexité sans bénéfice proportionné pour ce périmètre.
- Les tests de validation `uri` déjà en place (Prometheus/Grafana/Alertmanager/GLPI dans `deploy-monitoring.yml`, Node Exporter dans `deploy-node-exporter.yml`, la relecture de configuration dans `deploy-firewall-rules.yml`) testent ce qui compte le plus concrètement pour ce projet : est-ce que le service déployé répond réellement, pas seulement « la commande Ansible n'a pas renvoyé d'erreur ». C'est un test d'intégration réel, pas un simple contrôle de syntaxe.
- `ansible-playbook --syntax-check` (exécuté en CI sur les 4 playbooks) attrape les erreurs de structure YAML/Ansible avant tout déploiement.

Si le dépôt évolue vers des rôles réutilisables sur plusieurs projets, Molecule redevient pertinent — documenté ici comme évolution possible plutôt que comme prérequis non tenu, sur le même principe que pour Terratest côté Terraform (voir `../terraform/README.md`, section « Stratégie de tests »).
