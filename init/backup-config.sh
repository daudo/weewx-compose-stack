#!/bin/bash
set -e

# Centralized WeeWX Configuration Backup Management
# This script manages backup files to avoid excessive backups during initialization

WEEWX_CONF="/data/weewx.conf"
INIT_BACKUP="/data/weewx.conf.init-backup"

# Function to create initial backup if needed
create_initial_backup() {
    if [ -f "$WEEWX_CONF" ] && [ ! -f "$INIT_BACKUP" ]; then
        echo "Creating initial backup of weewx.conf..."
        cp "$WEEWX_CONF" "$INIT_BACKUP"
        echo "Initial backup saved as weewx.conf.init-backup"
    fi
}

# Function to clean up excessive backup files
cleanup_excess_backups() {
    echo "Cleaning up excess backup files..."
    
    # Count existing timestamped backups
    BACKUP_COUNT=$(ls -1 /data/weewx.conf.2* 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -gt 1 ]; then
        echo "Found $BACKUP_COUNT timestamped backups, keeping only the most recent..."
        
        # Keep only the most recent timestamped backup
        ls -t /data/weewx.conf.2* 2>/dev/null | tail -n +2 | while read backup_file; do
            echo "Removing excess backup: $(basename "$backup_file")"
            rm -f "$backup_file"
        done
    fi
    
    # Remove .backup files created by our scripts (not weectl)
    if [ -f "/data/weewx.conf.backup" ]; then
        echo "Removing script-generated backup file"
        rm -f "/data/weewx.conf.backup"
    fi
}

# Function to restore from backup if config is corrupted
restore_from_backup() {
    if [ ! -f "$WEEWX_CONF" ] || ! weectl extension list --config="$WEEWX_CONF" >/dev/null 2>&1; then
        echo "Config file missing or corrupted, attempting restore..."
        
        # Try to restore from init backup first
        if [ -f "$INIT_BACKUP" ]; then
            echo "Restoring from initial backup..."
            cp "$INIT_BACKUP" "$WEEWX_CONF"
            return 0
        fi
        
        # Try most recent timestamped backup
        LATEST_BACKUP=$(ls -t /data/weewx.conf.2* 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            echo "Restoring from latest backup: $(basename "$LATEST_BACKUP")"
            cp "$LATEST_BACKUP" "$WEEWX_CONF"
            return 0
        fi
        
        echo "No backup files found for restoration"
        return 1
    fi
    return 0
}

# Main backup management function
manage_backups() {
    case "${1:-cleanup}" in
        "init")
            create_initial_backup
            ;;
        "cleanup")
            cleanup_excess_backups
            ;;
        "restore")
            restore_from_backup
            ;;
        "all")
            create_initial_backup
            cleanup_excess_backups
            ;;
        *)
            echo "Usage: $0 {init|cleanup|restore|all}"
            exit 1
            ;;
    esac
}

# Execute the requested operation
manage_backups "$@"