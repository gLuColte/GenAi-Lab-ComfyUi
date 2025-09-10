#!/usr/bin/env bash
set -euo pipefail

# --- ENV NAME ---
if [ $# -eq 0 ]; then
    read -rp "Enter conda environment name: " ENV_NAME
else
    ENV_NAME="$1"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Initializing ComfyUI submodule..."
if [ ! -d "${REPO_ROOT}/comfyui" ]; then
    git submodule add https://github.com/comfyanonymous/ComfyUI.git comfyui
else
    git submodule update --init --recursive
fi

echo "🐍 Creating conda environment '${ENV_NAME}' with Python 3.12..."
conda create -y -n "${ENV_NAME}" python=3.12

echo "🔗 Activating environment..."
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${ENV_NAME}"

echo "🔥 Installing stable PyTorch (MPS support for Apple Silicon)..."
pip install -U pip wheel
pip install "torch==2.5.*" "torchvision==0.20.*" "torchaudio==2.5.*"

echo "📥 Installing ComfyUI requirements..."
pip install -r "${REPO_ROOT}/comfyui/requirements.txt"

echo "🧹 Removing torio (if present) to avoid FFmpeg extension issues..."
pip uninstall -y torio || true

echo "🎥 Installing safe video dependencies..."
pip install -U imageio[ffmpeg] av

echo "🔍 Verifying video deps..."
python - <<'PY'
import imageio_ffmpeg, av
print("✅ imageio-ffmpeg:", imageio_ffmpeg.get_ffmpeg_version())
print("✅ av:", av.__version__)
PY

echo "✅ Setup complete!"
echo "To start ComfyUI, run:"
echo "    conda activate ${ENV_NAME}"
echo "    export PYTORCH_ENABLE_MPS_FALLBACK=1"
echo "    python comfyui/main.py"

echo "🔍 Verifying MPS availability..."
python - <<'PY'
import torch
print("torch:", torch.__version__)
print("MPS available:", hasattr(torch.backends,"mps") and torch.backends.mps.is_available())
device = "mps" if hasattr(torch.backends,"mps") and torch.backends.mps.is_available() else "cpu"
print("tensor device:", torch.randn(2,3, device=device).device)
PY
