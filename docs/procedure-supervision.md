# Procédure de supervision — CYNA

## Services supervisés en phase locale

| Cible | Port | Description |
|---|---:|---|
| Prometheus | 9090 | Supervision centrale |
| Grafana | 3000 | Dashboards |
| Alertmanager | 9093 | Gestion des alertes |
| Node Exporter | 9100 | Métriques système |
| Blackbox Exporter | 9115 | Tests HTTP |
| GLPI | 8080 | Gestion des tickets d'incident (ITSM) |

## Vérifier les targets Prometheus

Dans l'interface Prometheus :

    Status > Targets

Les targets doivent être en état UP.

## Vérifier les alertes

Dans l'interface Prometheus :

    Alerts

Les règles disponibles sont :

- InstanceDown ;
- HighCpuLoad ;
- LowDiskSpace.

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
