#!/bin/bash
# ACE-Step REST API Server Launcher
# This script launches the REST API server for ACE-Step

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==================== Configuration ====================
# Uncomment and modify the parameters below as needed

# Server settings
HOST=127.0.0.1
#HOST=0.0.0.0
PORT=8001

# API key for authentication (optional)
#API_KEY="--api-key sk-your-secret-key"
API_KEY=""

# Download source settings
# Preferred download source: auto (default), huggingface, or modelscope
#DOWNLOAD_SOURCE="--download-source modelscope"
#DOWNLOAD_SOURCE="--download-source huggingface"
DOWNLOAD_SOURCE=""

# Update check settings
# Check for updates from GitHub before starting
CHECK_UPDATE=false
#CHECK_UPDATE=true

# ==================== Launch ====================

# Check for updates if enabled
if [ "$CHECK_UPDATE" = "true" ]; then
    echo "Checking for updates..."
    echo ""

    if [ -f "$SCRIPT_DIR/check_update.sh" ]; then
        bash "$SCRIPT_DIR/check_update.sh"
        UPDATE_CHECK_RESULT=$?

        if [ "$UPDATE_CHECK_RESULT" -eq 1 ]; then
            echo ""
            echo "[Error] Update check failed."
            echo "Continuing with startup..."
            echo ""
        elif [ "$UPDATE_CHECK_RESULT" -eq 2 ]; then
            echo ""
            echo "[Info] Update check skipped (network timeout)."
            echo "Continuing with startup..."
            echo ""
        fi

        # Wait a moment before starting
        sleep 2
    else
        echo "[Info] check_update.sh not found, skipping update check."
        echo ""
    fi
fi

echo "Starting ACE-Step REST API Server..."
echo "API will be available at: http://$HOST:$PORT"
echo "API Documentation: http://$HOST:$PORT/docs"
echo ""

# Check if uv is installed
if command -v uv >/dev/null 2>&1; then
    echo "[Environment] Using uv package manager..."
    echo ""

    # Check if virtual environment exists
    if [ ! -d "$SCRIPT_DIR/.venv" ]; then
        echo "[Setup] Virtual environment not found. Setting up environment..."
        echo "This will take a few minutes on first run."
        echo ""
        echo "Running: uv sync"
        echo ""

        cd "$SCRIPT_DIR"
        uv sync

        if [ $? -ne 0 ]; then
            echo ""
            echo "========================================"
            echo "[Error] Failed to setup environment"
            echo "========================================"
            echo ""
            echo "Please check the error messages above."
            echo "You may need to:"
            echo "  1. Check your internet connection"
            echo "  2. Ensure you have enough disk space"
            echo "  3. Try running: uv sync manually"
            echo ""
            read -p "Press Enter to continue..."
            exit 1
        fi

        echo ""
        echo "========================================"
        echo "Environment setup completed!"
        echo "========================================"
        echo ""
    fi

    echo "Starting ACE-Step API Server..."
    echo ""
    cd "$SCRIPT_DIR"
    uv run acestep-api \
        --host "$HOST" \
        --port "$PORT" \
        $API_KEY \
        $DOWNLOAD_SOURCE
elif [ -d "$SCRIPT_DIR/.venv" ]; then
    echo "[Environment] Using existing virtual environment..."
    source "$SCRIPT_DIR/.venv/bin/activate"
    python "$SCRIPT_DIR/acestep/api_server.py" \
        --host "$HOST" \
        --port "$PORT" \
        $API_KEY \
        $DOWNLOAD_SOURCE
elif [ -d "$SCRIPT_DIR/venv" ]; then
    echo "[Environment] Using existing virtual environment..."
    source "$SCRIPT_DIR/venv/bin/activate"
    python "$SCRIPT_DIR/acestep/api_server.py" \
        --host "$HOST" \
        --port "$PORT" \
        $API_KEY \
        $DOWNLOAD_SOURCE
else
    echo ""
    echo "========================================"
    echo "No Python environment found!"
    echo "========================================"
    echo ""
    echo "ACE-Step requires either:"
    echo "  1. uv package manager"
    echo "  2. A virtual environment (.venv or venv)"
    echo ""
    echo "Would you like to install uv now? (Recommended)"
    echo ""
    read -p "Install uv? (Y/N): " INSTALL_UV

    if [[ "${INSTALL_UV,,}" == "y" ]]; then
        echo ""
        echo "Installing uv..."
        echo ""
        curl -LsSf https://astral.sh/uv/install.sh | sh

        if [ $? -eq 0 ]; then
            # Source the env file
            [ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
            export PATH="$HOME/.local/bin:$PATH"

            if command -v uv >/dev/null 2>&1; then
                echo ""
                echo "========================================"
                echo "uv installed successfully!"
                echo "========================================"
                echo ""

                cd "$SCRIPT_DIR"
                if [ ! -d "$SCRIPT_DIR/.venv" ]; then
                    echo "[Setup] Setting up environment..."
                    uv sync
                fi

                echo "Starting ACE-Step API Server..."
                echo ""
                uv run acestep-api \
                    --host "$HOST" \
                    --port "$PORT" \
                    $API_KEY \
                    $DOWNLOAD_SOURCE
            else
                echo ""
                echo "uv installed but not in PATH yet."
                echo "Please restart your terminal and try again."
                echo ""
                read -p "Press Enter to continue..."
                exit 1
            fi
        else
            echo ""
            echo "========================================"
            echo "Installation failed!"
            echo "========================================"
            echo ""
            echo "Please install uv manually:"
            echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
            echo ""
            read -p "Press Enter to continue..."
            exit 1
        fi
    else
        echo ""
        echo "Installation cancelled."
        echo ""
        echo "To use ACE-Step, please install uv:"
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo ""
        read -p "Press Enter to continue..."
        exit 1
    fi
fi

read -p "Press Enter to continue..."
