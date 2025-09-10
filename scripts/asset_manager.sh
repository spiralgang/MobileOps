#!/bin/bash

# Asset Manager for MobileOps Platform
# Manages digital assets, files, and resources across the platform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/asset_manager.log"
ASSET_CONFIG_DIR="/etc/mobileops/assets"
ASSET_STORE_DIR="/var/lib/mobileops/assets"
ASSET_CACHE_DIR="/var/cache/mobileops/assets"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

initialize_asset_store() {
    log "INFO: Initializing asset store"
    
    mkdir -p "$ASSET_STORE_DIR"/{models,images,configs,binaries,docs}
    mkdir -p "$ASSET_CACHE_DIR"
    
    # Create asset index
    local index_file="$ASSET_CONFIG_DIR/asset_index.json"
    if [[ ! -f "$index_file" ]]; then
        cat > "$index_file" <<EOF
{
    "version": "1.0",
    "assets": {},
    "categories": {
        "models": "AI models and training data",
        "images": "Container and VM images",
        "configs": "Configuration templates",
        "binaries": "Executable binaries",
        "docs": "Documentation and guides"
    },
    "total_size": 0,
    "last_updated": "$(date -Iseconds)"
}
EOF
        log "INFO: Asset index initialized"
    fi
    
    log "INFO: Asset store initialized"
}

add_asset() {
    local asset_path="$1"
    local category="${2:-misc}"
    local description="${3:-No description}"
    
    log "INFO: Adding asset: $asset_path to category: $category"
    
    if [[ ! -f "$asset_path" ]]; then
        log "ERROR: Asset file not found: $asset_path"
        return 1
    fi
    
    local asset_name=$(basename "$asset_path")
    local asset_hash=$(sha256sum "$asset_path" | cut -d' ' -f1)
    local asset_size=$(stat -c%s "$asset_path")
    local target_dir="$ASSET_STORE_DIR/$category"
    
    mkdir -p "$target_dir"
    
    # Copy asset to store
    cp "$asset_path" "$target_dir/$asset_name"
    
    # Create asset metadata
    cat > "$target_dir/$asset_name.meta" <<EOF
{
    "name": "$asset_name",
    "category": "$category",
    "description": "$description",
    "hash": "$asset_hash",
    "size": $asset_size,
    "added_at": "$(date -Iseconds)",
    "source_path": "$asset_path",
    "mime_type": "$(file -b --mime-type "$asset_path" 2>/dev/null || echo 'unknown')"
}
EOF
    
    log "INFO: Asset $asset_name added successfully (size: $asset_size bytes, hash: $asset_hash)"
    update_asset_index
}

remove_asset() {
    local asset_name="$1"
    local category="${2:-}"
    
    log "INFO: Removing asset: $asset_name"
    
    local found=false
    
    if [[ -n "$category" ]]; then
        # Remove from specific category
        local asset_file="$ASSET_STORE_DIR/$category/$asset_name"
        if [[ -f "$asset_file" ]]; then
            rm -f "$asset_file" "$asset_file.meta"
            found=true
            log "INFO: Removed $asset_name from category $category"
        fi
    else
        # Search all categories
        find "$ASSET_STORE_DIR" -name "$asset_name" -type f | while read -r asset_file; do
            rm -f "$asset_file" "$asset_file.meta"
            found=true
            log "INFO: Removed $asset_name from $(dirname "$asset_file")"
        done
    fi
    
    if [[ "$found" == "false" ]]; then
        log "ERROR: Asset not found: $asset_name"
        return 1
    fi
    
    update_asset_index
}

list_assets() {
    local category="${1:-all}"
    
    log "INFO: Listing assets in category: $category"
    
    echo "=== ASSET INVENTORY ==="
    
    if [[ "$category" == "all" ]]; then
        for cat_dir in "$ASSET_STORE_DIR"/*; do
            if [[ -d "$cat_dir" ]]; then
                local cat_name=$(basename "$cat_dir")
                echo -e "\n[$cat_name]"
                list_category_assets "$cat_name"
            fi
        done
    else
        if [[ -d "$ASSET_STORE_DIR/$category" ]]; then
            echo "[$category]"
            list_category_assets "$category"
        else
            echo "Category not found: $category"
            return 1
        fi
    fi
}

list_category_assets() {
    local category="$1"
    local category_dir="$ASSET_STORE_DIR/$category"
    
    find "$category_dir" -maxdepth 1 -type f ! -name "*.meta" | while read -r asset_file; do
        local asset_name=$(basename "$asset_file")
        local meta_file="$asset_file.meta"
        
        if [[ -f "$meta_file" ]]; then
            local size=$(grep '"size"' "$meta_file" | cut -d':' -f2 | tr -d ' ,')
            local description=$(grep '"description"' "$meta_file" | cut -d'"' -f4)
            local added_at=$(grep '"added_at"' "$meta_file" | cut -d'"' -f4)
            
            printf "  %-30s %10s bytes  %s  %s\n" "$asset_name" "$size" "$(date -d "$added_at" +%Y-%m-%d 2>/dev/null || echo "$added_at")" "$description"
        else
            printf "  %-30s %10s bytes  %s  %s\n" "$asset_name" "unknown" "unknown" "No metadata"
        fi
    done
}

search_assets() {
    local search_term="$1"
    
    log "INFO: Searching for assets: $search_term"
    
    echo "=== ASSET SEARCH RESULTS ==="
    
    find "$ASSET_STORE_DIR" -type f -name "*$search_term*" ! -name "*.meta" | while read -r asset_file; do
        local asset_name=$(basename "$asset_file")
        local category=$(basename "$(dirname "$asset_file")")
        local meta_file="$asset_file.meta"
        
        echo "Found: $asset_name (category: $category)"
        
        if [[ -f "$meta_file" ]]; then
            local description=$(grep '"description"' "$meta_file" | cut -d'"' -f4)
            echo "  Description: $description"
        fi
        echo ""
    done
}

verify_asset() {
    local asset_name="$1"
    local category="${2:-}"
    
    log "INFO: Verifying asset integrity: $asset_name"
    
    local asset_files=()
    
    if [[ -n "$category" ]]; then
        asset_files=("$ASSET_STORE_DIR/$category/$asset_name")
    else
        mapfile -t asset_files < <(find "$ASSET_STORE_DIR" -name "$asset_name" -type f ! -name "*.meta")
    fi
    
    if [[ ${#asset_files[@]} -eq 0 ]]; then
        log "ERROR: Asset not found: $asset_name"
        return 1
    fi
    
    for asset_file in "${asset_files[@]}"; do
        local meta_file="$asset_file.meta"
        
        if [[ -f "$meta_file" ]]; then
            local expected_hash=$(grep '"hash"' "$meta_file" | cut -d'"' -f4)
            local actual_hash=$(sha256sum "$asset_file" | cut -d' ' -f1)
            
            if [[ "$expected_hash" == "$actual_hash" ]]; then
                echo "✓ $(basename "$asset_file"): Integrity verified"
            else
                echo "✗ $(basename "$asset_file"): Integrity check FAILED"
                log "ERROR: Hash mismatch for $asset_file - Expected: $expected_hash, Actual: $actual_hash"
                return 1
            fi
        else
            echo "? $(basename "$asset_file"): No metadata available"
        fi
    done
}

cache_asset() {
    local asset_name="$1"
    local category="$2"
    
    log "INFO: Caching asset: $asset_name from category: $category"
    
    local asset_file="$ASSET_STORE_DIR/$category/$asset_name"
    local cache_file="$ASSET_CACHE_DIR/$asset_name"
    
    if [[ ! -f "$asset_file" ]]; then
        log "ERROR: Asset not found: $asset_file"
        return 1
    fi
    
    cp "$asset_file" "$cache_file"
    log "INFO: Asset cached: $cache_file"
}

cleanup_cache() {
    local max_age="${1:-7}"  # days
    
    log "INFO: Cleaning up cache (files older than $max_age days)"
    
    find "$ASSET_CACHE_DIR" -type f -mtime "+$max_age" -delete
    
    local remaining_files=$(find "$ASSET_CACHE_DIR" -type f | wc -l)
    log "INFO: Cache cleanup completed. Remaining files: $remaining_files"
}

update_asset_index() {
    log "INFO: Updating asset index"
    
    local index_file="$ASSET_CONFIG_DIR/asset_index.json"
    local total_size=0
    local asset_count=0
    
    # Calculate total size and count
    find "$ASSET_STORE_DIR" -type f ! -name "*.meta" | while read -r asset_file; do
        local size=$(stat -c%s "$asset_file" 2>/dev/null || echo "0")
        echo "$size"
    done | {
        while read -r size; do
            total_size=$((total_size + size))
            asset_count=$((asset_count + 1))
        done
        
        log "INFO: Asset index updated - Total assets: $asset_count, Total size: $total_size bytes"
    }
}

backup_assets() {
    local backup_location="${1:-/tmp}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_location/mobileops_assets_$timestamp.tar.gz"
    
    log "INFO: Creating asset backup: $backup_file"
    
    tar -czf "$backup_file" -C "$(dirname "$ASSET_STORE_DIR")" "$(basename "$ASSET_STORE_DIR")"
    
    if [[ -f "$backup_file" ]]; then
        local backup_size=$(stat -c%s "$backup_file")
        log "INFO: Asset backup created successfully (size: $backup_size bytes)"
        echo "Backup created: $backup_file"
    else
        log "ERROR: Failed to create asset backup"
        return 1
    fi
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$ASSET_CONFIG_DIR" "$ASSET_STORE_DIR" "$ASSET_CACHE_DIR"
    log "INFO: Asset Manager started"
    
    case "${1:-list}" in
        "init")
            initialize_asset_store
            ;;
        "add")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 add <asset_path> [category] [description]"
                exit 1
            fi
            add_asset "$2" "${3:-misc}" "${4:-No description}"
            ;;
        "remove")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 remove <asset_name> [category]"
                exit 1
            fi
            remove_asset "$2" "${3:-}"
            ;;
        "list")
            list_assets "${2:-all}"
            ;;
        "search")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 search <search_term>"
                exit 1
            fi
            search_assets "$2"
            ;;
        "verify")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 verify <asset_name> [category]"
                exit 1
            fi
            verify_asset "$2" "${3:-}"
            ;;
        "cache")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 cache <asset_name> <category>"
                exit 1
            fi
            cache_asset "$2" "$3"
            ;;
        "cleanup")
            cleanup_cache "${2:-7}"
            ;;
        "backup")
            backup_assets "${2:-/tmp}"
            ;;
        *)
            echo "Usage: $0 {init|add|remove|list|search|verify|cache|cleanup|backup} [args]"
            exit 1
            ;;
    esac
}

main "$@"