#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$HOME/cyna-backups"
DATE=$(date +%F-%H%M)
BACKUP_FILE="$BACKUP_DIR/cyna-devops-$DATE.tar.gz"
GLPI_DUMP_FILE="$BACKUP_DIR/cyna-glpi-db-$DATE.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "[CYNA] Création de la sauvegarde depuis : $PROJECT_DIR"

tar -czf "$BACKUP_FILE" \
  -C "$(dirname "$PROJECT_DIR")" \
  "$(basename "$PROJECT_DIR")"

echo "[CYNA] Backup créé : $BACKUP_FILE"

if docker ps --format '{{.Names}}' | grep -q '^cyna-glpi-db$'; then
  echo "[CYNA] Sauvegarde de la base GLPI..."
  # shellcheck disable=SC2016 # variables evaluees dans le conteneur, pas sur l'hote
  docker exec cyna-glpi-db sh -c 'exec mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
    | gzip > "$GLPI_DUMP_FILE"
  echo "[CYNA] Dump GLPI créé : $GLPI_DUMP_FILE"
else
  echo "[CYNA] cyna-glpi-db non démarré : dump GLPI ignoré."
fi
