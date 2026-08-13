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
| AD-GE-01 / AD-GE-02 / FILE-GE-01 | 10.10.30.10/11/20 | `windows-exporter-infra` | **Non couvert par ce dépôt** : nécessite `windows_exporter` installé manuellement (pas de playbook WinRM fourni) |

Tant que Node Exporter (ou windows_exporter) n'est pas installé sur une cible, elle apparaît "down" dans Prometheus (`Status > Targets`) — c'est attendu en cours de déploiement, pas une erreur de configuration.

### Déployer Node Exporter sur les machines Linux

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy-node-exporter.yml
```

Ce playbook cible le groupe `[infra_linux]` de `ansible/inventory.ini` (IP à jour avec le plan d'adressage du CDC). Il suppose un accès SSH déjà en place depuis la VM DevOps vers ces machines, et ouvre le port 9100 côté service ; la règle firewall correspondante (VLAN 50 → cible) reste à valider manuellement (cf. CDC section 11.2).

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

## Vérification des services

Après le déploiement de la stack DevOps, les services peuvent être vérifiés avec le script suivant :

```bash
bash scripts/check-services.sh
```
