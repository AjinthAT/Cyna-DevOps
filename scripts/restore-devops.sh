#!/bin/bash

set -e

BACKUP_FILE="$1"
GLPI_DUMP_FILE="$2"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESTORE_PARENT="$(dirname "$PROJECT_DIR")"

if [ -z "$BACKUP_FILE" ]; then
  echo "[ERREUR] Usage : ./scripts/restore-devops.sh /chemin/backup.tar.gz [/chemin/glpi-db.sql.gz]"
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

if [ -n "$GLPI_DUMP_FILE" ]; then
  if [ ! -f "$GLPI_DUMP_FILE" ]; then
    echo "[ERREUR] Dump GLPI introuvable : $GLPI_DUMP_FILE"
    exit 1
  fi

  echo "[CYNA] Attente de la disponibilité de la base GLPI..."
  # shellcheck disable=SC2016 # variables evaluees dans le conteneur, pas sur l'hote
  until docker exec cyna-glpi-db sh -c 'mysqladmin ping -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent' >/dev/null 2>&1; do
    sleep 3
  done

  echo "[CYNA] Restauration de la base GLPI depuis : $GLPI_DUMP_FILE"
  # shellcheck disable=SC2016 # variables evaluees dans le conteneur, pas sur l'hote
  gunzip -c "$GLPI_DUMP_FILE" | docker exec -i cyna-glpi-db sh -c 'exec mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'

  echo "[CYNA] Base GLPI restaurée."
else
  echo "[CYNA] Aucun dump GLPI fourni : la base GLPI repart vide (nouvelle installation)."
fi

echo "[CYNA] Restauration terminée."
