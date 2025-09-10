#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# One script for macOS (MPS) and Linux (CUDA/CPU)
# - Auto-detects OS & GPUs
# - Picks correct PyTorch wheels (MPS / cu121 / CPU)
# - Sets up ComfyUI + safe video deps
# =========================================================

have() { command -v "$1" >/dev/null 2>&1; }

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux"  ]]; }

gpu_count_nvidia() {
  if have nvidia-smi; then
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | wc -l | tr -d ' '
  else
    echo 0
  fi
}

pkg_install_ffmpeg_hint() {
  if is_macos; then
    echo "brew install ffmpeg   # (optional) if you use Homebrew"
    return
  fi
  if have apt-get; then
    echo "sudo apt-get update && sudo apt-get install -y ffmpeg"
  elif have dnf; then
    echo "sudo dnf install -y ffmpeg"
  elif have pacman; then
    echo "sudo pacman -S --noconfirm ffmpeg"
  elif have zypper; then
    echo "sudo zypper install -y ffmpeg"
  else
    echo "Use your distro's package manager to install ffmpeg."
  fi
}

choose_torch_index_url() {
  # macOS: stock wheels include MPS (no special index needed)
  if is_macos; then
    echo ""   # empty → default PyPI
    return
  fi

  # Linux: prefer CUDA (if NVIDIA GPUs are visible)
  if [[ "$(gpu_count_nvidia)" -gt 0 ]]; then
    echo "https://download.pytorch.org/whl/cu121"
  else
    echo "https://download.pytorch.org/whl/cpu"
  fi
}

# -------------------------
# ENV NAME
# -------------------------
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

echo "🐍 Creating conda env '${ENV_NAME}' (Python 3.12)..."
conda create -y -n "${ENV_NAME}" python=3.12

echo "🔗 Activating env..."
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${ENV_NAME}"

TORCH_INDEX_URL="$(choose_torch_index_url)"

echo "⬆️  Upgrading pip/wheel..."
pip install -U pip wheel

if is_macos; then
  echo "🍏 Detected macOS → installing standard PyTorch wheels (MPS enabled)."
  pip install "torch==2.5.*" "torchvision==0.20.*" "torchaudio==2.5.*"
else
  if [[ "$TORCH_INDEX_URL" == *cu121* ]]; then
    echo "🔥 Detected NVIDIA GPUs → installing CUDA wheels (cu121)."
  else
    echo "ℹ️  No NVIDIA GPUs detected → installing CPU-only PyTorch wheels."
  fi
  pip install --index-url "$TORCH_INDEX_URL" \
    "torch==2.5.*" "torchvision==0.20.*" "torchaudio==2.5.*"
fi

echo "📥 Installing ComfyUI requirements..."
pip install -r "${REPO_ROOT}/comfyui/requirements.txt"

echo "🧹 Removing torio (if present) to avoid FFmpeg C++ extension issues..."
pip uninstall -y torio || true

echo "🎥 Installing video deps (imageio-ffmpeg & PyAV)..."
pip install -U imageio[ffmpeg] av

# ffmpeg system binary hint (optional but nice to have)
if ! have ffmpeg; then
  echo "🔎 'ffmpeg' system binary not found. Optional but recommended. Try:"
  echo "   $(pkg_install_ffmpeg_hint)"
fi

echo "🔍 Sanity checks..."
python - <<'PY'
import sys, platform
import torch
print("OS:", platform.platform())
print("torch:", torch.__version__)
if hasattr(torch.backends,"mps"):
    print("MPS available:", torch.backends.mps.is_available())
print("cuda.is_available:", torch.cuda.is_available())
print("cuda.device_count:", torch.cuda.device_count())
if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        print(f"  GPU[{i}] ->", torch.cuda.get_device_name(i))
try:
    import imageio_ffmpeg, av
    print("ffmpeg (imageio):", imageio_ffmpeg.get_ffmpeg_version())
    print("pyav:", av.__version__)
except Exception as e:
    print("Video deps check warning:", e, file=sys.stderr)
PY

echo "✅ Setup complete!"
echo

# -------------------------
# Run instructions (per platform)
# -------------------------
if is_macos; then
  echo "🚀 Run ComfyUI on Apple Silicon (MPS):"
  cat <<'EOF'
  conda activate '"$ENV_NAME"'
  cd comfyui
  export PYTORCH_ENABLE_MPS_FALLBACK=1
  python main.py --normalvram
EOF
  echo "Open: http://127.0.0.1:8188"
else
  NGPUS="$(gpu_count_nvidia)"
  if [[ "$NGPUS" -gt 0 ]]; then
    echo "🚀 Run ComfyUI on NVIDIA (each GPU on its own port):"
    BASE_PORT=8188
    for ((i=0; i<NGPUS; i++)); do
      PORT=$(( BASE_PORT + i*100 ))
      echo
      echo "GPU $i:"
      echo "  conda activate ${ENV_NAME}"
      echo "  cd comfyui"
      echo "  python main.py --gpu-only --cuda-device ${i} --port ${PORT} --normalvram"
    done
    echo
    read -rp "Write helper run scripts (scripts/run_gpu*.sh) [y/N]? " WRITE_SCRIPTS
    if [[ "${WRITE_SCRIPTS,,}" == "y" ]]; then
      mkdir -p "${REPO_ROOT}/scripts"
      for ((i=0; i<NGPUS; i++)); do
        PORT=$(( 8188 + i*100 ))
        cat > "${REPO_ROOT}/scripts/run_gpu${i}.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "\$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${ENV_NAME}"
cd "${REPO_ROOT}/comfyui"
python main.py --gpu-only --cuda-device ${i} --port ${PORT} --normalvram
EOF
        chmod +x "${REPO_ROOT}/scripts/run_gpu${i}.sh"
        echo "  → scripts/run_gpu${i}.sh"
      done
    fi
    echo
    echo "Open: http://127.0.0.1:8188 (GPU0), http://127.0.0.1:8288 (GPU1), etc."
  else
    echo "🖥️  No NVIDIA GPUs detected (Linux) → CPU-only mode (slow):"
    echo "  conda activate ${ENV_NAME}"
    echo "  cd comfyui"
    echo "  python main.py --cpu"
    echo "Open: http://127.0.0.1:8188"
  fi
fi
