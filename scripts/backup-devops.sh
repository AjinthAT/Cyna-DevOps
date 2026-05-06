#!/bin/bash

set -e

BACKUP_DIR="$HOME/cyna-backups"
DATE=$(date +%F-%H%M)

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/cyna-devops-$DATE.tar.gz" \
  "$HOME/cyna-devops" \
  2>/dev/null

echo "Backup créé : $BACKUP_DIR/cyna-devops-$DATE.tar.gz"
