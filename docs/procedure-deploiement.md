# Procédure de déploiement — DevOps CYNA

## Prérequis

La VM DevOps doit disposer de :

- Ubuntu Server 24.04 LTS ;
- Git ;
- Docker ;
- Docker Compose ;
- Ansible.

## Déploiement manuel

Cloner le repository :

    git clone https://github.com/AjinthAT/Cyna-DevOps.git
    cd Cyna-DevOps

Lancer la stack de supervision :

    cd monitoring
    docker compose up -d --build

## Déploiement via script

Depuis la racine du repository :

    ./scripts/deploy-monitoring.sh

## Déploiement via Ansible

Depuis la racine du repository :

    ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy-monitoring.yml --ask-become-pass

## Vérification

Vérifier les conteneurs :

    docker ps

Vérifier Prometheus :

    curl http://localhost:9090/-/healthy

Vérifier le webhook incident :

    curl http://localhost:5000/health

## Interfaces disponibles

| Service | URL |
|---|---|
| Prometheus | http://IP_VM:9090 |
| Grafana | http://IP_VM:3000 |
| Alertmanager | http://IP_VM:9093 |
| Incident Webhook | http://IP_VM:5000/incidents |
| Node Exporter | http://IP_VM:9100/metrics |
| Blackbox Exporter | http://IP_VM:9115 |
