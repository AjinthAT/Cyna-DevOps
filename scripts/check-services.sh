#!/bin/bash
set -e

echo "[CYNA] Vérification des services DevOps"

echo "[TEST] Prometheus"
curl -f http://localhost:9090/-/healthy

echo "[TEST] Grafana"
curl -f http://localhost:3000/api/health

echo "[TEST] Alertmanager"
curl -f http://localhost:9093/-/healthy

echo "[CYNA] Tous les services DevOps sont disponibles."
