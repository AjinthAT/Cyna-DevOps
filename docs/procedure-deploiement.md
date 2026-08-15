# Procédure de déploiement — DevOps CYNA

## Prérequis

La VM DevOps doit disposer de :

- Ubuntu Server 24.04 LTS ;
- Git ;
- Docker (avec le plugin Docker Compose v2, `docker compose`) ;
- Ansible.

### Installer Docker et le plugin Compose

Le paquet `docker-compose-plugin` n'existe pas dans les dépôts Ubuntu par
défaut (seul `docker.io`, sans le plugin Compose v2, y est présent) : il
faut ajouter le dépôt officiel Docker.

```bash
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
# se déconnecter/reconnecter (ou `newgrp docker`) pour que ça s'applique
```

Vérifier ensuite :

```bash
docker compose version
```

L'ensemble de ce dépôt (docker-compose.yml, scripts, CI) utilise la
syntaxe `docker compose` (v2, sans tiret) — pas l'ancien binaire
`docker-compose` (v1) des dépôts Ubuntu, déprécié et non maintenu.

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

## Interfaces disponibles

| Service | URL |
|---|---|
| Prometheus | http://IP_VM:9090 |
| Grafana | http://IP_VM:3000 |
| Alertmanager | http://IP_VM:9093 |
| GLPI | http://IP_VM:8080 |
| Node Exporter | http://IP_VM:9100/metrics |
| Blackbox Exporter | http://IP_VM:9115 |
