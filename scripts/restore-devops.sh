#!/bin/bash
set -e

BACKUP_DIR=${1:-"./backup"}

echo "[CYNA] Restauration de la stack DevOps depuis : $BACKUP_DIR"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "[ERREUR] Dossier de sauvegarde introuvable : $BACKUP_DIR"
  exit 1
fi

echo "[CYNA] Arrêt de la stack de supervision..."
docker compose -f monitoring/docker-compose.yml down || true

echo "[CYNA] Restauration des fichiers de configuration..."
cp -r "$BACKUP_DIR/monitoring" ./ || true
cp -r "$BACKUP_DIR/incident-webhook" ./ || true

echo "[CYNA] Redémarrage de la stack DevOps..."
docker compose -f monitoring/docker-compose.yml up -d --build

echo "[CYNA] Restauration terminée."
