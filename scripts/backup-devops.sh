#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$HOME/cyna-backups"
DATE=$(date +%F-%H%M)
BACKUP_FILE="$BACKUP_DIR/cyna-devops-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "[CYNA] Création de la sauvegarde depuis : $PROJECT_DIR"

tar -czf "$BACKUP_FILE" \
  -C "$(dirname "$PROJECT_DIR")" \
  "$(basename "$PROJECT_DIR")"

echo "[CYNA] Backup créé : $BACKUP_FILE"
