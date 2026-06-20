#!/bin/bash
# vault-restore.sh — Restore GPG-encrypted vault backup
# Usage: vault-restore.sh [backup-file]
# If no file specified, uses the latest backup from OneDrive

BACKUP_DIR="/mnt/c/Users/mbank/OneDrive/vault"
PASSPHRASE_FILE="$HOME/.oracle/.vault-passphrase"
RESTORE_DIR="$HOME/.oracle/security"

BACKUP_FILE="${1:-$(ls -t "$BACKUP_DIR"/oracle-vault-*.enc 2>/dev/null | head -1)}"

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: No backup file found. Usage: vault-restore.sh [backup-file]"
  echo "Available backups:"
  ls -lh "$BACKUP_DIR"/oracle-vault-*.enc 2>/dev/null || echo "  (none)"
  exit 1
fi

if [ ! -f "$PASSPHRASE_FILE" ]; then
  echo "ERROR: Passphrase file missing at $PASSPHRASE_FILE"
  exit 1
fi

echo "Restoring from: $BACKUP_FILE"
echo "Restoring to: $RESTORE_DIR"
echo ""

# Decrypt + extract to temp dir first
TEMP_DIR=$(mktemp -d)
gpg --batch --yes --passphrase-file "$PASSPHRASE_FILE" --decrypt "$BACKUP_FILE" 2>/dev/null | \
  tar xf - -C "$TEMP_DIR" 2>/dev/null

if [ $? -eq 0 ] && [ -d "$TEMP_DIR/security" ]; then
  FILE_COUNT=$(find "$TEMP_DIR/security" -type f | wc -l)
  echo "Decrypted $FILE_COUNT files:"
  ls -la "$TEMP_DIR/security/"
  echo ""

  read -p "Overwrite $RESTORE_DIR? (y/N): " CONFIRM
  if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
    mkdir -p "$RESTORE_DIR"
    cp -r "$TEMP_DIR/security/"* "$RESTORE_DIR/"
    echo "Restored $FILE_COUNT files to $RESTORE_DIR"
  else
    echo "Cancelled. Files available at: $TEMP_DIR/security/"
    exit 0
  fi
  rm -rf "$TEMP_DIR"
else
  echo "ERROR: Decryption failed"
  rm -rf "$TEMP_DIR"
  exit 1
fi
