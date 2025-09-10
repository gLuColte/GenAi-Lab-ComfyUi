#!/usr/bin/env bash
set -euo pipefail

# This script lives in workflows/1_simple_i2v/
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODELS_DIR="${REPO_ROOT}/comfyui/models"

# Folders
DIFF_DIR="${MODELS_DIR}/diffusion_models"
CKPT_DIR="${MODELS_DIR}/checkpoints"
VAE_DIR="${MODELS_DIR}/vae"
LORA_DIR="${MODELS_DIR}/loras"
TEXT_DIR="${MODELS_DIR}/text_encoders"

mkdir -p "$DIFF_DIR" "$CKPT_DIR" "$VAE_DIR" "$LORA_DIR" "$TEXT_DIR"

# Make checkpoints -> diffusion_models symlink (so both paths work)
if [ -e "$CKPT_DIR" ] && [ ! -L "$CKPT_DIR" ]; then
  echo "ℹ️  '$CKPT_DIR' exists and is not a symlink; leaving as-is."
else
  ln -sfn "diffusion_models" "$CKPT_DIR"
fi

echo "📥 Downloading WAN 2.2 I2V (FP16) models into: ${DIFF_DIR}"

# curl options: resume, follow redirects, fail on 4xx/5xx, retry a few times
CURL_OPTS=( -C - -L --fail --retry 5 --retry-delay 3 --progress-bar )

ensure_not_html () {
  local dest="$1"
  # basic sanity: non-tiny, non-HTML
  if [ ! -s "$dest" ] || [ "$(wc -c < "$dest")" -lt 2048 ]; then
    echo "❌ $dest looks too small."; return 1
  fi
  if head -c 200 "$dest" | grep -qiE '<!DOCTYPE html|<html|<head|<body'; then
    echo "❌ $dest looks like HTML (error page)."; return 1
  fi
}

download () {
  local url="$1"; local dest="$2"
  if [ -s "$dest" ]; then
    echo "  ✅ Already exists, skipping: $dest"; return
  fi
  echo "  ↳ Downloading: $dest"
  curl "${CURL_OPTS[@]}" -o "$dest" "${url}?download=1" || { echo "❌ Failed: $dest"; rm -f "$dest"; exit 1; }
  ensure_not_html "$dest" || { echo "❌ Invalid content: $dest"; rm -f "$dest"; exit 1; }
}

# ========= Diffusion Models (FP16, per tutorial) =========
download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors" \
         "${DIFF_DIR}/wan2.2_i2v_low_noise_14B_fp16.safetensors"

download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors" \
         "${DIFF_DIR}/wan2.2_i2v_high_noise_14B_fp16.safetensors"

# ================= LoRAs =================
download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
         "${LORA_DIR}/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"

download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
         "${LORA_DIR}/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"

# ================= VAE =================
download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
         "${VAE_DIR}/wan_2.1_vae.safetensors"

# ============ Text Encoder ============
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
         "${TEXT_DIR}/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

echo "✅ All models are present under comfyui/models/. ('diffusion_models/' is used; 'checkpoints/' is symlinked.)"
