#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
python -m pip install --upgrade pip -q 2>/dev/null

echo "========================================"
echo "ACE-Step Model Downloader for XPU"
echo "========================================"
echo ""
echo "Select models to download:"
echo ""
echo "[1] Quick Start (Turbo + 1.7B LM) - ~8 GB"
echo "    Fast generation, good quality"
echo ""
echo "[2] Studio Grade (Base + 4B LM) - ~13 GB"
echo "    Best quality, slower generation"
echo ""
echo "[3] Complete (All models) - ~20 GB"
echo "    Maximum flexibility"
echo ""
read -p "Enter choice (1-3): " choice

case "$choice" in
    1)
        echo ""
        echo "Downloading Quick Start setup..."
        echo "- acestep-v15-turbo (Fast DiT)"
        echo "- acestep-5Hz-lm-1.7B (Balanced LM)"
        echo ""
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-v15-turbo', local_dir='checkpoints/acestep-v15-turbo')"
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-5Hz-lm-1.7B', local_dir='checkpoints/acestep-5Hz-lm-1.7B')"
        ;;
    2)
        echo ""
        echo "Downloading Studio Grade setup..."
        echo "- acestep-v15-base (Studio DiT)"
        echo "- acestep-5Hz-lm-4B (Best LM)"
        echo ""
        echo "This may take 30-60 minutes..."
        echo ""
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-v15-base', local_dir='checkpoints/acestep-v15-base', max_workers=1)"
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-5Hz-lm-4B', local_dir='checkpoints/acestep-5Hz-lm-4B', max_workers=1)"
        ;;
    3)
        echo ""
        echo "Downloading ALL models..."
        echo "This will take 1-2 hours depending on connection..."
        echo ""
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-v15-turbo', local_dir='checkpoints/acestep-v15-turbo')"
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-v15-base', local_dir='checkpoints/acestep-v15-base', max_workers=1)"
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-5Hz-lm-0.6B', local_dir='checkpoints/acestep-5Hz-lm-0.6B')"
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-5Hz-lm-1.7B', local_dir='checkpoints/acestep-5Hz-lm-1.7B')"
        python -c "from huggingface_hub import snapshot_download; snapshot_download('ACE-Step/acestep-5Hz-lm-4B', local_dir='checkpoints/acestep-5Hz-lm-4B', max_workers=1)"
        ;;
    *)
        echo "Invalid choice!"
        read -p "Press Enter to continue..."
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "Download complete!"
echo "========================================"
echo ""
echo "You can now run the UI:"
echo "- ./run_xpu.sh (manual model selection)"
echo "- ./run_turbo.sh (quick start)"
echo "- ./run_studio.sh (best quality)"
echo ""
read -p "Press Enter to continue..."
