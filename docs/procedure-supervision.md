# Procédure de supervision — CYNA

## Services supervisés en phase locale

| Cible | Port | Description |
|---|---:|---|
| Prometheus | 9090 | Supervision centrale |
| Grafana | 3000 | Dashboards |
| Alertmanager | 9093 | Gestion des alertes |
| Node Exporter | 9100 | Métriques système |
| Blackbox Exporter | 9115 | Tests HTTP |
| Incident Webhook | 5000 | Simulation SOAR / ServiceNow |

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
- Webhook incidents.

URL du webhook :

    http://IP_VM:5000/incidents

Relancer Node Exporter :

    docker start cyna-node-exporter

## Exemple d'incident généré

Le webhook enregistre les alertes sous forme JSON avec :

- timestamp ;
- statut de l'alerte ;
- labels ;
- source ;
- outil.
