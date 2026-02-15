#!/bin/bash
cd "$(dirname "$0")"

echo "========================================"
echo "ACE-Step 1.5 for Intel XPU"
echo "========================================"

source .venv/bin/activate

python -m pip install --upgrade pip -q 2>/dev/null

# Set Intel XPU environment variables
export SYCL_CACHE_PERSISTENT=1
export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export PYTORCH_DEVICE=xpu

# Ensure required packages
pip install -q vector-quantize-pytorch torchao 2>/dev/null

echo ""
echo "XPU Environment Ready"
echo "Starting Gradio UI..."
echo ""
echo "Server: http://127.0.0.1:7860"
echo ""
echo "Select your model in the UI Service Configuration section!"
echo ""

python acestep/acestep_v15_pipeline.py --port 7860

read -p "Press Enter to continue..."
