#!/bin/bash
# Common Utilities for WeeWX Extension Management
# Provides shared functions for extension patching and configuration backup

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    echo "ℹ $*"
}

log_success() {
    echo "✓ $*"
}

log_warning() {
    echo "⚠ $*"
}

log_error() {
    echo "✗ $*" >&2
}

# =============================================================================
# Enhanced Patch Management System
# =============================================================================

# Apply patch files with intelligent ordering, dry-run testing, and conflict detection
apply_patch_files() {
    local patch_dir="$(dirname "$0")/patches"
    
    if [ ! -d "$patch_dir" ]; then
        log_info "No patches directory found at $patch_dir"
        return 0
    fi
    
    log_info "Applying patch files from $patch_dir"
    
    # Apply patches in numerical order to handle dependencies
    local patch_count=0
    local applied_count=0
    
    for patch_file in "$patch_dir"/*.patch; do
        if [ -f "$patch_file" ]; then
            patch_count=$((patch_count + 1))
            local patch_name=$(basename "$patch_file")
            
            echo "[$patch_count] Applying $patch_name..."
            
            # Test if patch can be applied (dry run)
            if cat "$patch_file" | patch -p0 -d /data --dry-run >/dev/null 2>&1; then
                # Apply the patch
                if cat "$patch_file" | patch -p0 -d /data; then
                    log_success "Successfully applied $patch_name"
                    applied_count=$((applied_count + 1))
                else
                    log_error "Failed to apply $patch_name (application error)"
                    return 1
                fi
            else
                log_warning "Skipping $patch_name (already applied or conflicts)"
                # Check if already applied by testing reverse patch
                if cat "$patch_file" | patch -p0 -d /data -R --dry-run >/dev/null 2>&1; then
                    log_info "$patch_name appears to be already applied"
                    applied_count=$((applied_count + 1))
                else
                    log_error "$patch_name has conflicts and cannot be applied"
                    return 1
                fi
            fi
        fi
    done
    
    log_success "Patch application completed: $applied_count/$patch_count patches applied"
    return 0
}

# =============================================================================
# Configuration Backup
# =============================================================================

WEEWX_CONF="/data/weewx.conf"
INIT_BACKUP="/data/weewx.conf.init-backup"

# Create initial backup if needed
create_initial_backup() {
    if [ -f "$WEEWX_CONF" ] && [ ! -f "$INIT_BACKUP" ]; then
        log_info "Creating initial backup of weewx.conf..."
        cp "$WEEWX_CONF" "$INIT_BACKUP"
        log_success "Initial backup saved as weewx.conf.init-backup"
    fi
}

# Clean up excessive backup files
cleanup_excess_backups() {
    log_info "Cleaning up excess backup files..."
    
    # Count existing timestamped backups
    BACKUP_COUNT=$(ls -1 /data/weewx.conf.2* 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -gt 1 ]; then
        log_info "Found $BACKUP_COUNT timestamped backups, keeping only the most recent..."
        
        # Keep only the most recent timestamped backup
        ls -t /data/weewx.conf.2* 2>/dev/null | tail -n +2 | while read backup_file; do
            log_info "Removing excess backup: $(basename "$backup_file")"
            rm -f "$backup_file"
        done
    fi
    
    # Remove .backup files created by our scripts (not weectl)
    if [ -f "/data/weewx.conf.backup" ]; then
        log_info "Removing script-generated backup file"
        rm -f "/data/weewx.conf.backup"
    fi
}

# Restore from backup if config is corrupted
restore_from_backup() {
    if [ ! -f "$WEEWX_CONF" ] || ! weectl extension list --config="$WEEWX_CONF" >/dev/null 2>&1; then
        log_warning "Config file missing or corrupted, attempting restore..."
        
        # Try to restore from init backup first
        if [ -f "$INIT_BACKUP" ]; then
            log_info "Restoring from initial backup..."
            cp "$INIT_BACKUP" "$WEEWX_CONF"
            return 0
        fi
        
        # Try most recent timestamped backup
        LATEST_BACKUP=$(ls -t /data/weewx.conf.2* 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            log_info "Restoring from latest backup: $(basename "$LATEST_BACKUP")"
            cp "$LATEST_BACKUP" "$WEEWX_CONF"
            return 0
        fi
        
        log_error "No backup files found for restoration"
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
            log_error "Usage: manage_backups {init|cleanup|restore|all}"
            return 1
            ;;
    esac
}

