#!/bin/bash
# ACE-Step Gradio Web UI Launcher
# This script launches the Gradio web interface for ACE-Step

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==================== Configuration ====================
# Uncomment and modify the parameters below as needed

# Server settings
PORT=7860
SERVER_NAME=127.0.0.1
#SERVER_NAME=0.0.0.0
#SHARE="--share"
SHARE=""

# UI language: en, zh, ja
LANGUAGE=en

# Model settings
CONFIG_PATH="--config_path acestep-v15-turbo"
LM_MODEL_PATH="--lm_model_path acestep-5Hz-lm-0.6B"
#OFFLOAD_TO_CPU="--offload_to_cpu true"
OFFLOAD_TO_CPU=""

# Download source settings
# Preferred download source: auto (default), huggingface, or modelscope
#DOWNLOAD_SOURCE="--download-source modelscope"
#DOWNLOAD_SOURCE="--download-source huggingface"
DOWNLOAD_SOURCE=""

# Update check settings
# Check for updates from GitHub before starting
CHECK_UPDATE=false
#CHECK_UPDATE=true

# Auto-initialize models on startup
INIT_SERVICE="--init_service true"

# API settings (enable REST API alongside Gradio)
#ENABLE_API="--enable-api"
ENABLE_API=""
#API_KEY="--api-key sk-your-secret-key"
API_KEY=""

# Authentication settings
#AUTH_USERNAME="--auth-username admin"
AUTH_USERNAME=""
#AUTH_PASSWORD="--auth-password password"
AUTH_PASSWORD=""

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

echo "Starting ACE-Step Gradio Web UI..."
echo "Server will be available at: http://$SERVER_NAME:$PORT"
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

    echo "Starting ACE-Step Gradio UI..."
    echo ""
    cd "$SCRIPT_DIR"
    uv run acestep \
        --port "$PORT" \
        --server-name "$SERVER_NAME" \
        --language "$LANGUAGE" \
        $SHARE \
        $CONFIG_PATH \
        $LM_MODEL_PATH \
        $OFFLOAD_TO_CPU \
        $DOWNLOAD_SOURCE \
        $INIT_SERVICE \
        $ENABLE_API \
        $API_KEY \
        $AUTH_USERNAME \
        $AUTH_PASSWORD
elif [ -d "$SCRIPT_DIR/.venv" ]; then
    echo "[Environment] Using existing virtual environment..."
    source "$SCRIPT_DIR/.venv/bin/activate"
    python "$SCRIPT_DIR/acestep/acestep_v15_pipeline.py" \
        --port "$PORT" \
        --server-name "$SERVER_NAME" \
        --language "$LANGUAGE" \
        $SHARE \
        $CONFIG_PATH \
        $LM_MODEL_PATH \
        $OFFLOAD_TO_CPU \
        $DOWNLOAD_SOURCE \
        $INIT_SERVICE \
        $ENABLE_API \
        $API_KEY \
        $AUTH_USERNAME \
        $AUTH_PASSWORD
elif [ -d "$SCRIPT_DIR/venv" ]; then
    echo "[Environment] Using existing virtual environment..."
    source "$SCRIPT_DIR/venv/bin/activate"
    python "$SCRIPT_DIR/acestep/acestep_v15_pipeline.py" \
        --port "$PORT" \
        --server-name "$SERVER_NAME" \
        --language "$LANGUAGE" \
        $SHARE \
        $CONFIG_PATH \
        $LM_MODEL_PATH \
        $OFFLOAD_TO_CPU \
        $DOWNLOAD_SOURCE \
        $INIT_SERVICE \
        $ENABLE_API \
        $API_KEY \
        $AUTH_USERNAME \
        $AUTH_PASSWORD
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

                echo "Starting ACE-Step Gradio UI..."
                echo ""
                uv run acestep \
                    --port "$PORT" \
                    --server-name "$SERVER_NAME" \
                    --language "$LANGUAGE" \
                    $SHARE \
                    $CONFIG_PATH \
                    $LM_MODEL_PATH \
                    $OFFLOAD_TO_CPU \
                    $DOWNLOAD_SOURCE \
                    $INIT_SERVICE \
                    $ENABLE_API \
                    $API_KEY \
                    $AUTH_USERNAME \
                    $AUTH_PASSWORD
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
