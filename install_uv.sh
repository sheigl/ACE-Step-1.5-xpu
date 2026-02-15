#!/bin/bash
# Install uv Package Manager
# This script installs uv using the official installer

echo "========================================"
echo "Install uv Package Manager"
echo "========================================"
echo ""
echo "This script will install uv, a fast Python package manager."
echo "Installation location: ~/.local/bin/"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Check if uv is already installed
if command -v uv >/dev/null 2>&1; then
    echo "uv is already installed!"
    echo "Current version:"
    uv --version
    echo ""
    echo "Installation location:"
    which uv
    echo ""

    read -p "Reinstall uv? (Y/N): " REINSTALL
    if [[ "${REINSTALL,,}" != "y" ]]; then
        echo ""
        echo "Installation cancelled."
        read -p "Press Enter to continue..."
        exit 0
    fi
    echo ""
fi

echo "Installing uv..."
echo ""

# Check if curl is available
if command -v curl >/dev/null 2>&1; then
    echo "[Method] Using curl installer..."
    echo ""
    curl -LsSf https://astral.sh/uv/install.sh | sh
elif command -v wget >/dev/null 2>&1; then
    echo "[Method] Using wget installer..."
    echo ""
    wget -qO- https://astral.sh/uv/install.sh | sh
else
    echo "========================================"
    echo "ERROR: Neither curl nor wget found!"
    echo "========================================"
    echo ""
    echo "Please install curl or wget first:"
    echo "  sudo apt install curl"
    echo "  sudo dnf install curl"
    echo ""
    echo "Or install uv manually from: https://astral.sh/uv"
    echo ""
    read -p "Press Enter to continue..."
    exit 1
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "Verifying installation..."

    # Source the env file if it exists
    if [ -f "$HOME/.local/bin/env" ]; then
        source "$HOME/.local/bin/env"
    fi

    # Also update PATH directly
    export PATH="$HOME/.local/bin:$PATH"

    if command -v uv >/dev/null 2>&1; then
        echo ""
        echo "========================================"
        echo "Installation successful!"
        echo "========================================"
        echo ""
        echo "uv version:"
        uv --version
        echo ""
        echo "Installation location:"
        which uv
        echo ""
        echo "You can now use ACE-Step by running:"
        echo "  ./start_gradio_ui.sh"
        echo "  ./start_api_server.sh"
        echo ""
    elif [ -f "$HOME/.local/bin/uv" ]; then
        echo ""
        echo "========================================"
        echo "Installation successful!"
        echo "========================================"
        echo ""
        echo "Installation location: $HOME/.local/bin/uv"
        echo ""
        echo "NOTE: uv is not in your PATH yet."
        echo "Please restart your terminal, or run:"
        echo "  source ~/.local/bin/env"
        echo ""
    else
        echo ""
        echo "========================================"
        echo "Installation completed but uv not found!"
        echo "========================================"
        echo ""
        echo "Please check the installation manually or try again."
        echo ""
    fi
    read -p "Press Enter to continue..."
    exit 0
else
    echo ""
    echo "========================================"
    echo "Installation failed!"
    echo "========================================"
    echo ""
    echo "Please try one of the following:"
    echo ""
    echo "1. Manual installation:"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo ""
    echo "2. Using pip:"
    echo "   pip install uv"
    echo ""
    echo "3. Check your internet connection and try again"
    echo ""
    read -p "Press Enter to continue..."
    exit 1
fi
