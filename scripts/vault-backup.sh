#!/bin/bash
# vault-backup.sh — GPG-encrypted backup of ~/.oracle/security/ to OneDrive
# Runs daily at 3:00 AM via maw loop
# ref: Office Improvement Plan Phase 2B — Trader+Scalper lost creds during migration

SECURITY_DIR="$HOME/.oracle/security"
BACKUP_DIR="/mnt/c/Users/mbank/OneDrive/vault"
DATE=$(date '+%Y%m%d')
BACKUP_FILE="$BACKUP_DIR/oracle-vault-${DATE}.enc"
PASSPHRASE_FILE="$HOME/.oracle/.vault-passphrase"
LOG="$HOME/.oracle/logs/vault-backup.log"

mkdir -p "$BACKUP_DIR" "$(dirname "$LOG")"

# Check passphrase exists
if [ ! -f "$PASSPHRASE_FILE" ]; then
  echo "$(date) | FAIL: passphrase file missing at $PASSPHRASE_FILE" >> "$LOG"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Admin-Oracle | $(hostname) | Notification | Admin-Oracle | maw-hey » needs your attention — vault backup FAILED: passphrase file missing" >> ~/.oracle/feed.log
  exit 1
fi

# Check security dir has files
FILE_COUNT=$(find "$SECURITY_DIR" -type f 2>/dev/null | wc -l)
if [ "$FILE_COUNT" -eq 0 ]; then
  echo "$(date) | FAIL: no files in $SECURITY_DIR" >> "$LOG"
  exit 1
fi

# Create tar + encrypt
tar cf - -C "$HOME/.oracle" security/ 2>/dev/null | \
  gpg --batch --yes --passphrase-file "$PASSPHRASE_FILE" --symmetric --cipher-algo AES256 \
  -o "$BACKUP_FILE" 2>/dev/null

if [ $? -eq 0 ] && [ -f "$BACKUP_FILE" ]; then
  SIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
  echo "$(date) | OK: backed up $FILE_COUNT files → $BACKUP_FILE ($SIZE)" >> "$LOG"

  # Prune old backups (keep last 7)
  ls -t "$BACKUP_DIR"/oracle-vault-*.enc 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null
  KEPT=$(ls "$BACKUP_DIR"/oracle-vault-*.enc 2>/dev/null | wc -l)
  echo "$(date) | Kept $KEPT backups (pruned older)" >> "$LOG"
else
  echo "$(date) | FAIL: GPG encryption failed" >> "$LOG"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Admin-Oracle | $(hostname) | Notification | Admin-Oracle | maw-hey » needs your attention — vault backup FAILED: GPG error" >> ~/.oracle/feed.log
  exit 1
fi
