#!/bin/bash
# Quick test for environment setup

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "Quick Environment Test"
echo "========================================"
echo ""

# Test 1: Check Python
echo "[Test 1] Checking Python..."
if command -v python3 >/dev/null 2>&1; then
    echo "[PASS] Python is available"
    python3 --version
elif command -v python >/dev/null 2>&1; then
    echo "[PASS] Python is available"
    python --version
else
    echo "[FAIL] Python not available"
fi
echo ""

# Test 2: Check pip
echo "[Test 2] Checking pip..."
if command -v pip3 >/dev/null 2>&1; then
    echo "[PASS] pip found"
    pip3 --version
elif command -v pip >/dev/null 2>&1; then
    echo "[PASS] pip found"
    pip --version
else
    echo "[INFO] pip not found"
fi
echo ""

# Test 3: Check for virtual environment
echo "[Test 3] Checking virtual environment..."
if [ -d "$SCRIPT_DIR/.venv" ]; then
    echo "[PASS] .venv found"
    if [ -f "$SCRIPT_DIR/.venv/bin/python" ]; then
        "$SCRIPT_DIR/.venv/bin/python" --version
    fi
elif [ -d "$SCRIPT_DIR/venv" ]; then
    echo "[PASS] venv found"
    if [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
        "$SCRIPT_DIR/venv/bin/python" --version
    fi
else
    echo "[INFO] No virtual environment found"
fi
echo ""

# Test 4: Check uv
echo "[Test 4] Checking uv..."
if command -v uv >/dev/null 2>&1; then
    echo "[PASS] uv found in PATH"
    uv --version
elif [ -f "$HOME/.local/bin/uv" ]; then
    echo "[INFO] uv exists at: $HOME/.local/bin/uv"
    "$HOME/.local/bin/uv" --version
else
    echo "[INFO] uv not installed"
fi
echo ""

# Test 5: Test internet connectivity
echo "[Test 5] Testing internet connectivity..."
if command -v curl >/dev/null 2>&1; then
    if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://astral.sh | grep -q "200\|301\|302"; then
        echo "[PASS] Can access astral.sh"
    else
        echo "[FAIL] Cannot access astral.sh"
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q --spider --timeout=5 https://astral.sh 2>/dev/null; then
        echo "[PASS] Can access astral.sh"
    else
        echo "[FAIL] Cannot access astral.sh"
    fi
else
    echo "[INFO] Neither curl nor wget available for connectivity test"
fi
echo ""

# Summary
echo "========================================"
echo "Summary"
echo "========================================"
echo ""

# Determine which environment will be used
ENV_FOUND=0

if command -v uv >/dev/null 2>&1; then
    echo "[RESULT] Will use: uv (from PATH)"
    echo "No additional setup needed!"
    ENV_FOUND=1
elif [ -f "$HOME/.local/bin/uv" ]; then
    echo "[RESULT] Will use: uv (not in PATH)"
    echo "Action: Add to PATH or restart terminal"
    echo "  source ~/.local/bin/env"
    ENV_FOUND=1
fi

if [ "$ENV_FOUND" -eq 0 ]; then
    if [ -d "$SCRIPT_DIR/.venv" ] || [ -d "$SCRIPT_DIR/venv" ]; then
        echo "[RESULT] Will use: existing virtual environment"
        ENV_FOUND=1
    fi
fi

if [ "$ENV_FOUND" -eq 0 ]; then
    echo "[RESULT] No environment found"
    echo "Action: Run ./start_gradio_ui.sh to install uv"
    echo "Or: Install manually with: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

echo ""
echo "========================================"
read -n 1 -s -r -p "Press any key to close..."
echo ""
