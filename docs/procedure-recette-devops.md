# Recette — Lot DevOps

Critères d'acceptation pour le lot DevOps (Git, Terraform, Ansible, CI/CD,
automatisation, documentation technique — cf. CDC section 3.1), sur le même
principe que la section 20 du CDC (« Critères de recette ») pour les lots
réseau/sécurité/PRA. Chaque test doit pouvoir être rejoué par un référent
autre que celui qui a construit le lot DevOps.

## Tests CI/CD

| Test | Preuve attendue | Résultat cible |
|---|---|---|
| Pipeline CI complet | Run GitHub Actions sur `feature/...` ou `main` (`.github/workflows/ci.yml`) | Jobs `validate`, `terraform-validate`, `helm-lint`, `integration-test` tous verts |
| Terraform statique | `terraform fmt -check -recursive` puis `terraform validate` dans `terraform/` | Aucun diff de formatage ; `Success! The configuration is valid.` |
| Helm statique | `helm lint helm/saas-app` puis `helm template saas-app helm/saas-app -f values.yaml` | Aucune erreur de lint ; manifestes rendus sans erreur |
| Scripts shell | `shellcheck scripts/*.sh` | Aucun avertissement/erreur |

## Tests de déploiement et d'automatisation

| Test | Preuve attendue | Résultat cible |
|---|---|---|
| Stack de supervision | `ansible-playbook ansible/playbooks/deploy-monitoring.yml` | Tests `uri` intégrés passent (Prometheus, Grafana, Alertmanager, GLPI) |
| Node Exporter infra | `ansible-playbook ansible/playbooks/deploy-node-exporter.yml` | Test `uri` intégré passe (`/metrics` sur le port 9100) ; cible visible dans Prometheus (`procedure-supervision.md`) |
| Firewall Zero Trust | `ansible-playbook ansible/playbooks/deploy-firewall-rules.yml` | Chaque règle de la matrice confirmée présente côté Sophos (assert intégré, voir `procedure-firewall-automation.md`) |
| Sauvegarde config firewall | `ansible-playbook ansible/playbooks/backup-firewall-config.yml` | Export daté non vide, contenant au moins une balise `<FirewallRule>` |
| Azure Arc | `ansible-playbook ansible/playbooks/onboard-azure-arc.yml` (après `terraform apply` réel) | Machine confirmée `Connected` (assert intégré) |
| Patch management | `ansible-playbook ansible/playbooks/patch-management.yml` | Rapport daté généré dans `/var/log/cyna-patch-management` sur chaque hôte |
| Autoscaling SaaS | Génération de charge sur le service, `kubectl get hpa -n saas saas-app` | Nombre de réplicas augmente entre `minReplicas` et `maxReplicas` (`helm/saas-app/README.md`) |

## Tests de la chaîne d'incident

| Test | Preuve attendue | Résultat cible |
|---|---|---|
| Détection → ticket automatique | Arrêter `cyna-node-exporter`, attendre ~90s (`procedure-supervision.md`, « Tester une alerte ») | Alerte visible dans Prometheus/Alertmanager, ticket créé automatiquement dans GLPI sans ressaisie manuelle |

## Tests PRA/PCA

| Test | Preuve attendue | Résultat cible |
|---|---|---|
| Restauration stack DevOps | `./scripts/restore-devops.sh` (`procedure-pra-pca.md`) | Prometheus/Grafana/Alertmanager répondent ; tickets GLPI antérieurs présents ; RTO < 30 min |
| PRA configurations IaC | `terraform plan` sur un environnement déjà appliqué (`procedure-pra-pca.md`, « PRA des configurations IaC ») | `No changes` — la configuration versionnée correspond à l'infrastructure réelle |
| Idempotence firewall | Rejouer `deploy-firewall-rules.yml` sans modification de la matrice | Aucune règle dupliquée ; test de validation intégré toujours au vert |
| Rollback Helm | `helm rollback saas-app -n saas` après une révision défectueuse | Révision précédente active ; autoscaling de nouveau fonctionnel |
| Rollback Docker Compose | `git checkout <commit précédent> -- monitoring/` puis redéploiement (`procedure-supervision.md`, « Rollback ») | Stack de supervision revenue à l'état antérieur |

## Écarts assumés (à ne pas traiter comme des échecs de recette)

Ces limites sont documentées et acceptées ailleurs dans le projet (CDC
section 9, « Risques et mesures de maîtrise ») ; les rejouer en recette
échouera nécessairement tant qu'elles ne sont pas levées, pour des raisons
externes au lot DevOps :

- `terraform apply` non joué sur l'abonnement Azure réel (pas d'identifiants
  Azure disponibles à ce stade) — `onboard-azure-arc.yml` ne peut donc pas
  encore être validé en conditions réelles ;
- VPN site-à-site vers Azure potentiellement bloqué par le NAT de
  l'environnement GNS3 — repli documenté sur Azure Arc/Monitor en HTTPS ;
- `deploy-firewall-rules.yml`/`backup-firewall-config.yml` non exécutés
  contre un vrai firewall Sophos dans cet environnement de rédaction — à
  valider sur la maquette GNS3 avant la démonstration finale ;
- Shuffle lui-même (SOAR) tourne sur une pile Docker Swarm séparée, non
  redéployée par ce dépôt (seul l'export du workflow y est versionné).
