#!/bin/bash
# Test Environment Auto-Detection
# This script tests the environment detection logic

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "ACE-Step Environment Detection Test"
echo "========================================"
echo ""

# Test 1: Check for virtual environment
echo "[Test 1] Checking for virtual environment..."
if [ -d "$SCRIPT_DIR/.venv" ] && [ -f "$SCRIPT_DIR/.venv/bin/python" ]; then
    echo "[PASS] .venv detected"
    echo "Location: $SCRIPT_DIR/.venv/bin/python"
    "$SCRIPT_DIR/.venv/bin/python" --version
elif [ -d "$SCRIPT_DIR/venv" ] && [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    echo "[PASS] venv detected"
    echo "Location: $SCRIPT_DIR/venv/bin/python"
    "$SCRIPT_DIR/venv/bin/python" --version
else
    echo "[INFO] No local virtual environment found"
fi
echo ""

# Test 2: Check if uv is available
echo "[Test 2] Checking for uv command..."
if command -v uv >/dev/null 2>&1; then
    echo "[PASS] uv detected"
    uv --version
else
    echo "[INFO] uv not found in PATH"
    echo "To install uv, run: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi
echo ""

# Test 3: Check project.scripts in pyproject.toml
echo "[Test 3] Checking project scripts..."
if [ -f "$SCRIPT_DIR/pyproject.toml" ]; then
    echo "[PASS] pyproject.toml found"
    echo ""
    echo "Available scripts:"
    grep 'acestep = ' "$SCRIPT_DIR/pyproject.toml" 2>/dev/null
    grep 'acestep-api = ' "$SCRIPT_DIR/pyproject.toml" 2>/dev/null
    grep 'acestep-download = ' "$SCRIPT_DIR/pyproject.toml" 2>/dev/null
else
    echo "[FAIL] pyproject.toml not found"
fi
echo ""

# Test 4: Determine which environment will be used
echo "[Test 4] Environment selection logic..."
if [ -d "$SCRIPT_DIR/.venv" ] && [ -f "$SCRIPT_DIR/.venv/bin/python" ]; then
    echo "[RESULT] Will use: Virtual environment (.venv)"
    echo "Command: .venv/bin/python acestep/acestep_v15_pipeline.py"
elif [ -d "$SCRIPT_DIR/venv" ] && [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    echo "[RESULT] Will use: Virtual environment (venv)"
    echo "Command: venv/bin/python acestep/acestep_v15_pipeline.py"
elif command -v uv >/dev/null 2>&1; then
    echo "[RESULT] Will use: uv package manager"
    echo "Command: uv run acestep"
else
    echo "[ERROR] Neither virtual environment nor uv found!"
    echo "Please install uv or create a virtual environment."
fi
echo ""

echo "========================================"
echo "Test Complete"
echo "========================================"
read -p "Press Enter to continue..."
