#!/bin/bash

set -e

BACKUP_FILE="$1"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESTORE_PARENT="$(dirname "$PROJECT_DIR")"

if [ -z "$BACKUP_FILE" ]; then
  echo "[ERREUR] Usage : ./scripts/restore-devops.sh /chemin/backup.tar.gz"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "[ERREUR] Archive introuvable : $BACKUP_FILE"
  exit 1
fi

echo "[CYNA] Arrêt de la stack DevOps..."
docker compose -f "$PROJECT_DIR/monitoring/docker-compose.yml" down || true

echo "[CYNA] Sauvegarde temporaire du dossier actuel..."
mv "$PROJECT_DIR" "$PROJECT_DIR.before-restore-$(date +%F-%H%M)"

echo "[CYNA] Restauration depuis : $BACKUP_FILE"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_PARENT"

echo "[CYNA] Redémarrage de la stack DevOps..."
docker compose -f "$PROJECT_DIR/monitoring/docker-compose.yml" up -d --build

echo "[CYNA] Restauration terminée."
