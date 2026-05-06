#!/bin/bash

set -e

cd "$(dirname "$0")/../monitoring"

echo "[CYNA] Démarrage de la stack monitoring..."
docker compose up -d

echo "[CYNA] État des conteneurs :"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "[CYNA] Déploiement terminé."
