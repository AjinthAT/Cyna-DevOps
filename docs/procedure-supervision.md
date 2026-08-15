# Procédure de supervision — CYNA

## Services supervisés en phase locale

| Cible | Port | Description |
|---|---:|---|
| Prometheus | 9090 | Supervision centrale |
| Grafana | 3000 | Dashboards |
| Alertmanager | 9093 | Gestion des alertes |
| Node Exporter | 9100 | Métriques système (VM DevOps elle-même) |
| Blackbox Exporter | 9115 | Tests HTTP |
| GLPI | 8080 | Gestion des tickets d'incident (ITSM) |

## Cibles supervisées sur l'infrastructure Genève

Depuis la mise à jour du plan Prometheus (`monitoring/prometheus/prometheus.yml`), les machines Genève du CDC (section 10.5.1) sont déclarées comme cibles, en plus de la VM DevOps :

| Machine | IP | Job Prometheus | Statut |
|---|---|---|---|
| SAAS-GE-01 | 10.10.40.10 | `linux-node-exporter-infra`, `blackbox-saas-site` | Nécessite Node Exporter (voir plus bas) |
| APP-BACKEND-01 | 10.10.45.10 | `linux-node-exporter-infra` | Nécessite Node Exporter |
| WAZUH-GE-01 | 10.10.50.10 | `linux-node-exporter-infra`, `blackbox-wazuh-dashboard` | Nécessite Node Exporter |
| BACKUP-GE-01 | 10.10.60.10 | `linux-node-exporter-infra` | Nécessite Node Exporter |
| AD-GE-01 / AD-GE-02 / FILE-GE-01 | 10.10.30.10/11/20 | `windows-exporter-infra` | Nécessite windows_exporter (voir plus bas) |

Tant que Node Exporter (ou windows_exporter) n'est pas installé sur une cible, elle apparaît "down" dans Prometheus (`Status > Targets`) — c'est attendu en cours de déploiement, pas une erreur de configuration.

### Déployer Node Exporter sur les machines Linux

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy-node-exporter.yml
```

Ce playbook cible le groupe `[infra_linux]` de `ansible/inventory.ini` (IP à jour avec le plan d'adressage du CDC). Il suppose un accès SSH déjà en place depuis la VM DevOps vers ces machines, et ouvre le port 9100 côté service ; la règle firewall correspondante (VLAN 50 → cible) reste à valider manuellement (cf. CDC section 11.2).

### Déployer windows_exporter sur les machines Windows

```bash
source .env.local
ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy-windows-exporter.yml
```

Ce playbook cible le groupe `[infra_windows]` (AD-GE-01, AD-GE-02, FILE-GE-01) via WinRM plutôt que SSH. Prérequis, avant de le lancer :

- WinRM déjà activé côté Windows (script `ConfigureRemotingForAnsible.ps1` de Microsoft ou GPO du domaine) — Ansible ne peut pas l'activer à distance sur une machine qui ne l'a pas déjà ;
- les collections `ansible.windows`/`community.windows` installées (`ansible-galaxy collection install -r ansible/requirements.yml`) et `pywinrm` (`pip install pywinrm`) ;
- `WINDOWS_ADMIN_USER`/`WINDOWS_ADMIN_PASSWORD` renseignés dans `.env.local` (voir `.env.example`).

Comme pour Node Exporter, le port ouvert (9182) nécessite que la règle firewall inter-VLAN correspondante (VLAN 50 → cible) soit validée côté Sophos (cf. CDC section 11.2).

## Vérifier les targets Prometheus

Dans l'interface Prometheus :

    Status > Targets

Les targets doivent être en état UP.

## Vérifier les alertes

Dans l'interface Prometheus :

    Alerts

Les règles disponibles sont :

- InstanceDown (une cible ne répond plus) ;
- HighCpuLoad (> 80% de CPU) ;
- LowDiskSpace (< 15% d'espace disque libre) ;
- ServiceHttpDown (une sonde blackbox échoue — SaaS, Wazuh, ou services internes) ;
- ServiceSlowResponse (une sonde blackbox met plus de 2s à répondre).

Le dashboard Grafana « CYNA - Supervision DevOps » (`monitoring/grafana/dashboards/cyna-overview.json`) visualise désormais les métriques associées à chacune de ces règles (CPU, disque, disponibilité et latence HTTP), pas seulement l'état UP/DOWN global.

## Tester une alerte

Arrêter Node Exporter :

    docker stop cyna-node-exporter

Attendre environ 90 secondes.

Vérifier ensuite :

- Prometheus > Alerts ;
- Alertmanager ;
- GLPI > Assistance > Tickets (nouveau ticket créé via Shuffle).

Relancer Node Exporter :

    docker start cyna-node-exporter

Voir `procedure-shuffle-glpi.md` pour le détail de la chaîne d'automatisation du ticket.

## Rollback

Contrairement à Helm (historique de révisions natif, voir
`helm/saas-app/README.md`), Docker Compose n'a pas de mécanisme de rollback
intégré : revenir en arrière consiste à redéployer une version antérieure de
la configuration versionnée dans Git, sur le même principe que le rollback
Terraform (`terraform/README.md`, section « Rollback et journalisation »).

```bash
# Revenir à la configuration monitoring d'un commit antérieur
git log --oneline -- monitoring/
git checkout <commit précédent> -- monitoring/

# Redéployer avec la configuration restaurée
cd monitoring
docker compose up -d --build
```

Si la régression vient d'une image tierce (ex. nouvelle version de
`prom/prometheus` cassant la compatibilité), épingler une version connue
dans `monitoring/docker-compose.yml` (`image: prom/prometheus:v2.x.y` au
lieu de `:latest`) plutôt que de dépendre de la dernière image publiée.

## Vérification des services

Après le déploiement de la stack DevOps, les services peuvent être vérifiés avec le script suivant :

```bash
bash scripts/check-services.sh
```
