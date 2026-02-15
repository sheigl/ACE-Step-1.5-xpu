#!/bin/bash
echo "========================================"
echo "ACE-Step for Intel XPU - Installation"
echo "========================================"
echo ""

# Check Python version
if ! python3 --version 2>/dev/null; then
    echo "ERROR: Python not found! Please install Python 3.10 or 3.11"
    echo "Install with your package manager, e.g.:"
    echo "  sudo apt install python3 python3-venv python3-pip"
    read -p "Press Enter to continue..."
    exit 1
fi

echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo ""
echo "Upgrading pip..."
python -m pip install --upgrade pip

echo ""
echo "Installing Intel PyTorch XPU (nightly build)..."
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/xpu

echo ""
echo "Installing Intel Extension for PyTorch..."
pip install intel-extension-for-pytorch

echo ""
echo "Installing ACE-Step and dependencies..."
pip install -e .

echo ""
echo "Installing additional packages..."
pip install accelerate diffusers gradio soundfile librosa scipy
pip install vector-quantize-pytorch torchao

echo ""
echo "========================================"
read -p "Install training dependencies (lightning, peft)? (y/n): " training
if [[ "${training,,}" == "y" ]]; then
    echo "Installing training packages..."
    pip install lightning peft
fi

echo ""
echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Run ./download_models.sh to download AI models"
echo "2. Run ./run_xpu.sh to start the UI"
echo ""
read -p "Press Enter to continue..."
