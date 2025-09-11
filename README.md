# GenAI-Lab-ComfyUi

This project is a lightweight testbed for running **[ComfyUI](https://github.com/comfyanonymous/ComfyUI)** on:

- Apple Silicon (M3, M2, M1) using **PyTorch MPS acceleration**  
- NVIDIA GPUs (e.g. RTX 4060 Ti) using **CUDA acceleration**

The goal is to spin up ComfyUI completely from scratch in an isolated conda environment, test example workflows, and benchmark performance across different hardware backends.

---

## Installation

### Requirements
- macOS (Apple Silicon M3 recommended) **OR** Linux with NVIDIA GPU (tested on RTX 4060 Ti, CUDA 12.1)  
- [conda](https://docs.conda.io/en/latest/) or [miniconda](https://docs.conda.io/en/latest/miniconda.html)  
- Git  

---

### Steps (Apple Silicon)

Absolutely—here’s a clean, copy-pasteable set of Apple-Silicon-friendly steps with the right PyTorch Nightly and ComfyUI bits wired up.

### ComfyUI on Apple Silicon (M-series)

1. **Clone the repo (with submodules)**

```bash
git clone --recurse-submodules https://github.com/<your-username>/GenAI-Lab-ComfyUi.git
cd GenAI-Lab-ComfyUi
```

2. **Create & activate a Conda env (Python 3.11)**

```bash
conda create -n comfyui-env python=3.11 -y
conda activate comfyui-env
```

3. **Install PyTorch Nightly (MPS)**

> Nightly is recommended for the latest MPS fixes on macOS.

```bash
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cpu
```

4. **Install ComfyUI dependencies**

```bash
# If the ComfyUI submodule folder is "comfyui" (lowercase—as in your repo):
pip install -r comfyui/requirements.txt
```

5. **(Optional) Quick MPS sanity check**

```bash
python - <<'PY'
import torch
print("PyTorch:", torch.__version__)
print("MPS available:", torch.backends.mps.is_available())
print("MPS built:", torch.backends.mps.is_built())
PY
```

6. **Run ComfyUI**

```bash
export PYTORCH_ENABLE_MPS_FALLBACK=1
# Helps avoid hard crashes when a node falls back to CPU.

python comfyui/main.py
# If you hit memory pressure on bigger graphs:
# python comfyui/main.py --lowvram
```

7. **Open the UI**

* After “Starting server”, open: `http://127.0.0.1:8188`

---

## Key Concepts in Image Generation (ComfyUI / SD)

| Term                               | What it is (simple)                                                  | Why it matters                                                                                   | Typical values / tips                                                                                                                          |
| ---------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **KSampler**                       | The “image cooker” – denoises latent noise into an image.            | Controls how the image forms step-by-step.                                                       | • **Steps**: 20–35 (fast vs. detailed). <br>• **Sampler**: *Euler a / Beta* → crisp lines (anime). <br> *DPM++ 2M Karras* → smooth, realistic. |
| **CFG (Classifier-Free Guidance)** | How strictly the model follows your text prompt.                     | Balance between creativity and prompt accuracy.                                                  | SD1.5: 6–8, SDXL: 5–7. <br> Lower = more free, higher = rigid/overbaked.                                                                       |
| **Seed**                           | Starting random noise pattern.                                       | Reproducibility: same seed + same settings → same image.                                         | Example: `3534616310`. Change seed for variety.                                                                                                |
| **VAE (Encode/Decode)**            | The “compressor/decompressor” between pixels and model latent space. | Needed for img2img & final rendering. Wrong VAE = muddy colors.                                  | Use the **VAE matching your base model**. <br>• SD1.5: *vae-ft-mse-840000*. <br>• SDXL: built-in is usually fine.                              |
| **LoRA (Low-Rank Adapter)**        | A lightweight style/concept add-on.                                  | Lets you apply specific styles (anime, Slam Dunk) or characters without swapping the base model. | • Must match base family (SD1.5 ↔ SD1.5, SDXL ↔ SDXL). <br>• Strengths: UNet 0.6–0.9, TE 0.4–0.8. <br>• Stackable but keep total < \~1.5–1.8.  |
| **Refiner**                        | A second pass model (mainly SDXL / Hunyuan) that polishes details.   | Improves textures, faces, contrast.                                                              | Usually enabled at **high steps** (e.g. Hunyuan: 50 steps + refiner ON).                                                                       |
| **Denoise strength**               | (Img2Img only) How much to change the source image.                  | Controls how much of the original survives.                                                      | 0.3–0.55 = refine but keep structure. <br>0.6–0.8 = big changes.                                                                               |

---

### Preset Examples

| Setup         | CFG | Steps | Sampler       | Notes                                         |
| ------------- | --- | ----- | ------------- | --------------------------------------------- |
| **Hunyuan**   | 3.5 | 50    | (unspecified) | Refiner ON, very polished, slow but detailed. |
| **Qwen**      | 4   | 25    | Euler Beta    | Clean, fast, good for anime.                  |
| **Flux Krea** | 4.5 | 25    | Euler Beta    | Similar to Qwen but stronger guidance.        |


---

## Workflows

This repo includes a set of curated ComfyUI workflows to show a progression
from beginner to advanced use cases.

| # | Workflow                  | Description |
| - | ------------------------- | ------------------------- |
| 1 | [Simple Image Generation](#1-simple-image-generation)   | Very Simple Image Generation using existing templates. |

---

### 1. Simple Image Generation



