#!/bin/bash
# Config Merge Helper
# This script helps merge backed up files with new version

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "ACE-Step Backup Merge Helper"
echo "========================================"
echo ""

# Check for backup directories
FOUND_BACKUPS=0
BACKUP_DIRS=()

echo "Searching for backup directories..."
echo ""

for d in "$SCRIPT_DIR"/.update_backup_*; do
    if [ -d "$d" ]; then
        FOUND_BACKUPS=1
        BACKUP_DIRS+=("$d")
        echo "Found backup: $(basename "$d")"
        echo "  Location: $d"
        echo "  Files:"
        find "$d" -type f | while read -r f; do
            echo "    - ${f#$d/}"
        done
        echo ""
    fi
done

if [ "$FOUND_BACKUPS" -eq 0 ]; then
    echo "No backup directories found."
    echo ""
    echo "Backups are created when updates conflict with your local changes."
    read -p "Press Enter to continue..."
    exit 0
fi

echo "========================================"
echo "Merge Options"
echo "========================================"
echo ""
echo "1. Compare backup with current files (opens diff)"
echo "2. Restore a file from backup (overwrites current)"
echo "3. List all backed up files"
echo "4. Delete old backups"
echo "5. Exit"
echo ""

read -p "Select option (1-5): " CHOICE

select_backup() {
    echo ""
    echo "Available backup directories:"
    local index=0
    local dirs=()
    for d in "$SCRIPT_DIR"/.update_backup_*; do
        if [ -d "$d" ]; then
            index=$((index + 1))
            dirs+=("$d")
            echo "$index. $(basename "$d")"
        fi
    done

    if [ "$index" -eq 0 ]; then
        echo "No backups found."
        read -p "Press Enter to continue..."
        return 1
    fi

    echo ""
    read -p "Select backup number: " BACKUP_CHOICE

    BACKUP_CHOICE=$((BACKUP_CHOICE - 1))
    if [ "$BACKUP_CHOICE" -ge 0 ] && [ "$BACKUP_CHOICE" -lt "${#dirs[@]}" ]; then
        SELECTED_BACKUP="${dirs[$BACKUP_CHOICE]}"
        return 0
    else
        echo "Invalid selection."
        read -p "Press Enter to continue..."
        return 1
    fi
}

case "$CHOICE" in
    1)
        echo ""
        echo "========================================"
        echo "Compare Files"
        echo "========================================"

        select_backup || exit 0

        echo ""
        echo "Files in backup:"
        find "$SELECTED_BACKUP" -type f | while read -r f; do
            echo "  - ${f#$SELECTED_BACKUP/}"
        done

        echo ""
        read -p "Enter filename to compare (e.g., start_gradio_ui.sh or acestep/handler.py): " FILE_NAME

        BACKUP_FILE="$SELECTED_BACKUP/$FILE_NAME"
        CURRENT_FILE="$SCRIPT_DIR/$FILE_NAME"

        if [ ! -f "$BACKUP_FILE" ]; then
            echo "Backup file not found: $BACKUP_FILE"
            read -p "Press Enter to continue..."
            exit 1
        fi

        if [ ! -f "$CURRENT_FILE" ]; then
            echo "Current file not found: $CURRENT_FILE"
            read -p "Press Enter to continue..."
            exit 1
        fi

        echo ""
        echo "Comparing files..."
        echo ""
        echo "Backup version:  $BACKUP_FILE"
        echo "Current version: $CURRENT_FILE"
        echo ""

        # Use diff to compare (or a visual tool if available)
        if command -v vimdiff >/dev/null 2>&1; then
            vimdiff "$BACKUP_FILE" "$CURRENT_FILE"
        elif command -v meld >/dev/null 2>&1; then
            meld "$BACKUP_FILE" "$CURRENT_FILE"
        elif command -v code >/dev/null 2>&1; then
            code --diff "$BACKUP_FILE" "$CURRENT_FILE"
        else
            diff --color -u "$BACKUP_FILE" "$CURRENT_FILE" | less
        fi

        echo ""
        echo "Compare the files and manually apply your configuration changes."
        echo ""
        read -p "Press Enter to continue..."
        ;;
    2)
        echo ""
        echo "========================================"
        echo "Restore File from Backup"
        echo "========================================"
        echo ""
        echo "[Warning] This will OVERWRITE the current file!"

        select_backup || exit 0

        echo ""
        echo "Files in backup:"
        find "$SELECTED_BACKUP" -type f | while read -r f; do
            echo "  - ${f#$SELECTED_BACKUP/}"
        done

        echo ""
        read -p "Enter filename to restore (e.g., start_gradio_ui.sh or acestep/handler.py): " FILE_NAME

        BACKUP_FILE="$SELECTED_BACKUP/$FILE_NAME"
        CURRENT_FILE="$SCRIPT_DIR/$FILE_NAME"

        if [ ! -f "$BACKUP_FILE" ]; then
            echo "Backup file not found: $BACKUP_FILE"
            read -p "Press Enter to continue..."
            exit 1
        fi

        echo ""
        echo "About to restore:"
        echo "  From: $BACKUP_FILE"
        echo "  To:   $CURRENT_FILE"
        echo ""
        read -p "Are you sure? This will overwrite the current file. (Y/N): " CONFIRM

        if [[ "${CONFIRM,,}" == "y" ]]; then
            if cp "$BACKUP_FILE" "$CURRENT_FILE"; then
                echo ""
                echo "[Success] File restored successfully."
            else
                echo ""
                echo "[Error] Failed to restore file."
            fi
        else
            echo ""
            echo "Restore cancelled."
        fi

        echo ""
        read -p "Press Enter to continue..."
        ;;
    3)
        echo ""
        echo "========================================"
        echo "All Backed Up Files"
        echo "========================================"
        echo ""

        for d in "$SCRIPT_DIR"/.update_backup_*; do
            if [ -d "$d" ]; then
                echo "Backup: $(basename "$d")"
                echo "Location: $d"
                echo "Files:"
                find "$d" -type f | while read -r f; do
                    echo "  - ${f#$d/}"
                done
                echo ""
            fi
        done

        read -p "Press Enter to continue..."
        ;;
    4)
        echo ""
        echo "========================================"
        echo "Delete Old Backups"
        echo "========================================"
        echo ""
        echo "[Warning] This will permanently delete backup directories!"
        echo ""
        echo "Available backups:"
        for d in "$SCRIPT_DIR"/.update_backup_*; do
            if [ -d "$d" ]; then
                echo "  - $(basename "$d")"
            fi
        done

        echo ""
        read -p "Delete all backups? (Y/N): " DELETE_CONFIRM

        if [[ "${DELETE_CONFIRM,,}" == "y" ]]; then
            echo ""
            echo "Deleting backups..."
            for d in "$SCRIPT_DIR"/.update_backup_*; do
                if [ -d "$d" ]; then
                    echo "  Deleting: $(basename "$d")"
                    rm -rf "$d"
                fi
            done
            echo ""
            echo "[Done] Backups deleted."
        else
            echo ""
            echo "Deletion cancelled."
        fi

        echo ""
        read -p "Press Enter to continue..."
        ;;
    5)
        exit 0
        ;;
    *)
        echo "Invalid choice."
        read -p "Press Enter to continue..."
        exit 1
        ;;
esac
