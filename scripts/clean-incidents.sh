#!/bin/bash

set -e

CONTAINER_NAME="cyna-incident-webhook"
INCIDENTS_FILE="/data/incidents.json"

echo "[CYNA] Nettoyage du fichier des incidents..."

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "[ERREUR] Le conteneur ${CONTAINER_NAME} n'est pas démarré."
  echo "[INFO] Lance la stack avec : docker compose -f monitoring/docker-compose.yml up -d"
  exit 1
fi

echo "[CYNA] Sauvegarde de l'ancien fichier incidents.json..."

docker exec "$CONTAINER_NAME" sh -c "
  if [ -f '$INCIDENTS_FILE' ]; then
    cp '$INCIDENTS_FILE' '${INCIDENTS_FILE}.bak'
  fi
"

echo "[CYNA] Réinitialisation des incidents..."

docker exec "$CONTAINER_NAME" sh -c "echo '[]' > '$INCIDENTS_FILE'"

echo "[CYNA] Vérification du fichier nettoyé :"

docker exec "$CONTAINER_NAME" cat "$INCIDENTS_FILE"

echo ""
echo "[CYNA] Nettoyage terminé."
