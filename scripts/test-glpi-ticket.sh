#!/bin/bash

set -euo pipefail

ENV_FILE=".env.local"

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERREUR] Fichier .env.local introuvable."
  echo "[INFO] Crée un fichier .env.local avec GLPI_URL, GLPI_APP_TOKEN et GLPI_USER_TOKEN."
  exit 1
fi

source "$ENV_FILE"

if [ -z "${GLPI_URL:-}" ] || [ -z "${GLPI_APP_TOKEN:-}" ] || [ -z "${GLPI_USER_TOKEN:-}" ]; then
  echo "[ERREUR] Variables GLPI manquantes dans .env.local."
  exit 1
fi

echo "[CYNA] Initialisation de la session GLPI..."

SESSION_RESPONSE=$(curl -sS -X GET "$GLPI_URL/initSession" \
  -H "App-Token: $GLPI_APP_TOKEN" \
  -H "Authorization: user_token $GLPI_USER_TOKEN")

SESSION_TOKEN=$(echo "$SESSION_RESPONSE" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("session_token", ""))')

if [ -z "$SESSION_TOKEN" ]; then
  echo "[ERREUR] Impossible de récupérer le session_token."
  echo "[DEBUG] Réponse GLPI : $SESSION_RESPONSE"
  exit 1
fi

echo "[CYNA] Session GLPI ouverte."

echo "[CYNA] Création du ticket d'incident..."

CREATE_RESPONSE=$(curl -sS -X POST "$GLPI_URL/Ticket" \
  -H "Content-Type: application/json" \
  -H "App-Token: $GLPI_APP_TOKEN" \
  -H "Session-Token: $SESSION_TOKEN" \
  -d '{
    "input": {
      "name": "[CYNA] Incident DevOps - node-exporter indisponible",
      "content": "Ticket généré automatiquement depuis un script DevOps. Le service node-exporter est utilisé pour simuler une panne de supervision. Impact : perte temporaire des métriques système de la VM DevOps.",
      "type": 1,
      "urgency": 4,
      "impact": 3,
      "priority": 4
    }
  }')

echo "[CYNA] Réponse GLPI :"
echo "$CREATE_RESPONSE"

echo "[CYNA] Fermeture de la session GLPI..."

curl -sS -X GET "$GLPI_URL/killSession" \
  -H "App-Token: $GLPI_APP_TOKEN" \
  -H "Session-Token: $SESSION_TOKEN" > /dev/null

echo "[CYNA] Test terminé. Vérifie le ticket dans GLPI : Assistance > Tickets."
