#!/bin/bash
# Git Update Check Utility
# This script checks for updates from GitHub and optionally updates the repository

# Configuration
TIMEOUT_SECONDS=10
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_PATH="$SCRIPT_DIR"
PROXY_CONFIG_FILE="$SCRIPT_DIR/proxy_config.txt"
GIT_CMD="git"

echo "========================================"
echo "ACE-Step Update Check"
echo "========================================"
echo ""

# Check if git is available
if ! command -v git >/dev/null 2>&1; then
    echo "[Error] git not found."
    echo "Please install git:"
    echo "  sudo apt install git"
    echo "  sudo dnf install git"
    echo ""
    echo "========================================"
    read -n 1 -s -r -p "Press any key to close..."
    echo ""
    exit 1
fi

# Check if this is a git repository
cd "$REPO_PATH"
if ! "$GIT_CMD" rev-parse --git-dir >/dev/null 2>&1; then
    echo "[Error] Not a git repository."
    echo "This folder does not appear to be a git repository."
    echo ""
    echo "========================================"
    read -n 1 -s -r -p "Press any key to close..."
    echo ""
    exit 1
fi

# Load proxy configuration if exists
PROXY_ENABLED=0
PROXY_URL=""
if [ -f "$PROXY_CONFIG_FILE" ]; then
    while IFS='=' read -r key value; do
        case "${key,,}" in
            proxy_enabled) PROXY_ENABLED="$value" ;;
            proxy_url) PROXY_URL="$value" ;;
        esac
    done < "$PROXY_CONFIG_FILE"

    if [ "$PROXY_ENABLED" = "1" ] && [ -n "$PROXY_URL" ]; then
        echo "[Proxy] Using proxy server: $PROXY_URL"
        "$GIT_CMD" config --local http.proxy "$PROXY_URL"
        "$GIT_CMD" config --local https.proxy "$PROXY_URL"
        echo ""
    fi
fi

echo "[1/4] Checking current version..."
# Get current branch
CURRENT_BRANCH=$("$GIT_CMD" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$CURRENT_BRANCH" ] && CURRENT_BRANCH="main"

# Get current commit
CURRENT_COMMIT=$("$GIT_CMD" rev-parse --short HEAD 2>/dev/null)

echo "  Branch: $CURRENT_BRANCH"
echo "  Commit: $CURRENT_COMMIT"
echo ""

configure_proxy() {
    echo ""
    echo "========================================"
    echo "Proxy Server Configuration"
    echo "========================================"
    echo ""
    echo "Please enter your proxy server URL."
    echo ""
    echo "Examples:"
    echo "  - HTTP proxy:  http://127.0.0.1:7890"
    echo "  - HTTPS proxy: https://proxy.example.com:8080"
    echo "  - SOCKS5:      socks5://127.0.0.1:1080"
    echo ""
    echo "Leave empty to disable proxy."
    echo ""
    read -p "Proxy URL: " NEW_PROXY_URL

    if [ -z "$NEW_PROXY_URL" ]; then
        echo ""
        echo "[Proxy] Disabling proxy..."
        "$GIT_CMD" config --local --unset http.proxy 2>/dev/null
        "$GIT_CMD" config --local --unset https.proxy 2>/dev/null
        cat > "$PROXY_CONFIG_FILE" <<EOF
PROXY_ENABLED=0
PROXY_URL=
EOF
        echo "[Proxy] Proxy disabled."
        return 0
    else
        echo ""
        echo "[Proxy] Configuring proxy: $NEW_PROXY_URL"
        "$GIT_CMD" config --local http.proxy "$NEW_PROXY_URL"
        "$GIT_CMD" config --local https.proxy "$NEW_PROXY_URL"
        cat > "$PROXY_CONFIG_FILE" <<EOF
PROXY_ENABLED=1
PROXY_URL=$NEW_PROXY_URL
EOF
        echo "[Proxy] Proxy configured successfully."
        echo "[Proxy] Configuration saved to: $PROXY_CONFIG_FILE"
        return 0
    fi
}

fetch_with_retry() {
    echo "[2/4] Checking for updates (timeout: ${TIMEOUT_SECONDS}s)..."
    echo "  Connecting to GitHub..."

    FETCH_SUCCESS=0

    # Try fetch with timeout
    if timeout "$TIMEOUT_SECONDS" "$GIT_CMD" fetch origin --quiet 2>/dev/null; then
        FETCH_SUCCESS=1
    else
        echo "  [Timeout] Could not connect to GitHub within $TIMEOUT_SECONDS seconds."
    fi

    if [ "$FETCH_SUCCESS" -eq 0 ]; then
        echo "  [Failed] Could not fetch from GitHub."
        echo "  Please check your internet connection."
        echo ""

        read -p "Do you want to configure a proxy server to retry? (Y/N): " PROXY_CHOICE
        if [[ "${PROXY_CHOICE,,}" == "y" ]]; then
            configure_proxy
            if [ $? -eq 0 ]; then
                echo ""
                echo "[Proxy] Retrying with proxy configuration..."
                echo ""
                fetch_with_retry
                return $?
            fi
        fi

        echo ""
        echo "========================================"
        read -n 1 -s -r -p "Press any key to close..."
        echo ""
        exit 2
    fi

    echo "  [Success] Fetched latest information from GitHub."
    echo ""
    return 0
}

fetch_with_retry

echo "[3/4] Comparing versions..."
# Get remote commit
REMOTE_COMMIT=$("$GIT_CMD" rev-parse --short "origin/$CURRENT_BRANCH" 2>/dev/null)

if [ -z "$REMOTE_COMMIT" ]; then
    echo "  [Warning] Remote branch 'origin/$CURRENT_BRANCH' not found."
    echo ""
    echo "  Your current branch '$CURRENT_BRANCH' does not exist on the remote repository."
    echo "  This might be a local development branch."
    echo ""

    # Try to get main branch instead
    FALLBACK_BRANCH="main"
    echo "  Checking main branch instead..."
    REMOTE_COMMIT=$("$GIT_CMD" rev-parse --short "origin/$FALLBACK_BRANCH" 2>/dev/null)

    if [ -z "$REMOTE_COMMIT" ]; then
        echo "  [Error] Could not find remote main branch either."
        echo "  Please ensure you are connected to the correct repository."
        echo ""
        echo "========================================"
        read -n 1 -s -r -p "Press any key to close..."
        echo ""
        exit 1
    fi

    echo "  Found main branch: $REMOTE_COMMIT"
    echo ""
    echo "  Recommendation: Switch to main branch to check for official updates."
    echo "  Command: git checkout main"
    echo ""

    read -p "Do you want to switch to main branch now? (Y/N): " SWITCH_BRANCH
    if [[ "${SWITCH_BRANCH,,}" == "y" ]]; then
        echo ""
        echo "  Switching to main branch..."
        if "$GIT_CMD" checkout main; then
            echo "  [Success] Switched to main branch."
            echo ""
            echo "  Please run this script again to check for updates."
            echo ""
            echo "========================================"
            read -n 1 -s -r -p "Press any key to close..."
            echo ""
            exit 0
        else
            echo "  [Error] Failed to switch branch."
            echo ""
            echo "========================================"
            read -n 1 -s -r -p "Press any key to close..."
            echo ""
            exit 1
        fi
    else
        echo ""
        echo "  Continuing with current branch comparison..."
        echo "  Note: This comparison may not reflect official updates."
        echo ""
        CURRENT_BRANCH="$FALLBACK_BRANCH"
    fi
fi

echo "  Local:  $CURRENT_COMMIT"
echo "  Remote: $REMOTE_COMMIT"
echo ""

# Compare commits
if [ "$CURRENT_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo "[4/4] Result: Already up to date!"
    echo "  You have the latest version."
    echo ""
    echo "========================================"
    read -n 1 -s -r -p "Press any key to close..."
    echo ""
    exit 0
fi

echo "[4/4] Result: Update available!"

# Check if local is behind remote
if "$GIT_CMD" merge-base --is-ancestor HEAD "origin/$CURRENT_BRANCH" 2>/dev/null; then
    echo "  A new version is available on GitHub."
    echo ""

    # Show commits behind
    echo "  New commits:"
    "$GIT_CMD" log --oneline --graph --decorate "HEAD..origin/$CURRENT_BRANCH" 2>/dev/null
    echo ""

    read -p "Do you want to update now? (Y/N): " UPDATE_CHOICE
    if [[ "${UPDATE_CHOICE,,}" == "y" ]]; then
        echo ""
        echo "Updating..."

        # Check for uncommitted changes
        if ! "$GIT_CMD" diff-index --quiet HEAD -- 2>/dev/null; then
            echo ""
            echo "[Info] Checking for potential conflicts..."

            # Get list of locally modified files
            TEMP_LOCAL_CHANGES=$(mktemp)
            "$GIT_CMD" diff --name-only HEAD 2>/dev/null > "$TEMP_LOCAL_CHANGES"

            # Get list of files changed in remote
            TEMP_REMOTE_CHANGES=$(mktemp)
            "$GIT_CMD" diff --name-only "HEAD..origin/$CURRENT_BRANCH" 2>/dev/null > "$TEMP_REMOTE_CHANGES"

            # Check for conflicts
            HAS_CONFLICTS=0
            BACKUP_DIR="$SCRIPT_DIR/.update_backup_$(date +%Y%m%d_%H%M%S)"

            while IFS= read -r local_file; do
                if grep -qxF "$local_file" "$TEMP_REMOTE_CHANGES" 2>/dev/null; then
                    HAS_CONFLICTS=1

                    # Create backup directory if not exists
                    if [ ! -d "$BACKUP_DIR" ]; then
                        mkdir -p "$BACKUP_DIR"
                        echo ""
                        echo "[Backup] Creating backup directory: $BACKUP_DIR"
                    fi

                    # Backup the file
                    echo "[Backup] Backing up: $local_file"
                    FILE_DIR=$(dirname "$local_file")
                    if [ -n "$FILE_DIR" ] && [ "$FILE_DIR" != "." ]; then
                        mkdir -p "$BACKUP_DIR/$FILE_DIR"
                    fi
                    cp "$local_file" "$BACKUP_DIR/$local_file" 2>/dev/null
                fi
            done < "$TEMP_LOCAL_CHANGES"

            # Clean up temp files
            rm -f "$TEMP_LOCAL_CHANGES" "$TEMP_REMOTE_CHANGES"

            if [ "$HAS_CONFLICTS" -eq 1 ]; then
                echo ""
                echo "========================================"
                echo "[Warning] Potential conflicts detected!"
                echo "========================================"
                echo ""
                echo "Your modified files may conflict with remote updates."
                echo "Your changes have been backed up to:"
                echo "  $BACKUP_DIR"
                echo ""
                echo "Update will restore these files to the remote version."
                echo "You can manually merge your changes later."
                echo ""
                read -p "Continue with update? (Y/N): " CONFLICT_CHOICE

                if [[ "${CONFLICT_CHOICE,,}" == "y" ]]; then
                    echo ""
                    echo "[Restore] Restoring conflicting files to remote version..."
                    "$GIT_CMD" reset --hard HEAD >/dev/null 2>&1
                    echo "[Restore] Files restored. Proceeding with update..."
                else
                    echo ""
                    echo "Update cancelled."
                    echo "Your backup remains at: $BACKUP_DIR"
                    echo ""
                    echo "========================================"
                    read -n 1 -s -r -p "Press any key to close..."
                    echo ""
                    exit 0
                fi
            else
                echo ""
                echo "[Info] No conflicts detected. Safe to stash and update."
                echo ""
                read -p "Stash your changes and continue? (Y/N): " STASH_CHOICE
                if [[ "${STASH_CHOICE,,}" == "y" ]]; then
                    echo "Stashing changes..."
                    "$GIT_CMD" stash push -m "Auto-stash before update - $(date)"
                else
                    echo ""
                    echo "Update cancelled."
                    echo ""
                    echo "========================================"
                    read -n 1 -s -r -p "Press any key to close..."
                    echo ""
                    exit 0
                fi
            fi
        fi

        # Pull changes
        echo "Pulling latest changes..."
        if "$GIT_CMD" pull origin "$CURRENT_BRANCH"; then
            echo ""
            echo "========================================"
            echo "Update completed successfully!"
            echo "========================================"
            echo ""

            # Check if backup was created
            if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
                echo "[Important] Your modified files were backed up to:"
                echo "  $BACKUP_DIR"
                echo ""
                echo "To restore your changes:"
                echo "  1. Run ./merge_config.sh to compare and merge files"
                echo "  2. Or manually compare backup with new version"
                echo ""
                echo "Backed up files:"
                find "$BACKUP_DIR" -type f | while read -r f; do
                    echo "  - ${f#$BACKUP_DIR/}"
                done
                echo ""
            fi

            echo "Please restart the application to use the new version."
            echo ""
            echo "========================================"
            read -n 1 -s -r -p "Press any key to close..."
            echo ""
            exit 0
        else
            echo ""
            echo "[Error] Update failed."
            echo "Please check the error messages above."

            if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
                echo ""
                echo "Your backup is still available at: $BACKUP_DIR"
            fi

            echo ""
            echo "========================================"
            read -n 1 -s -r -p "Press any key to close..."
            echo ""
            exit 1
        fi
    else
        echo ""
        echo "Update skipped."
        echo ""
        echo "========================================"
        read -n 1 -s -r -p "Press any key to close..."
        echo ""
        exit 0
    fi
else
    echo "  [Warning] Local version has diverged from remote."
    echo "  This might be because you have local commits."
    echo "  Please update manually or consult the documentation."
    echo ""
    echo "========================================"
    read -n 1 -s -r -p "Press any key to close..."
    echo ""
    exit 0
fi
