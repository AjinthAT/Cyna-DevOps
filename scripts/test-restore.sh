#!/bin/bash
set -e

echo "[CYNA] Vérification de disponibilité des services DevOps"

echo "[TEST] Prometheus"
curl -f http://localhost:9090/-/healthy

echo "[TEST] Alertmanager"
curl -f http://localhost:9093/-/healthy

echo "[TEST] Incident Webhook"
curl -f http://localhost:5000/health

echo "[CYNA] Tous les services DevOps sont disponibles."
