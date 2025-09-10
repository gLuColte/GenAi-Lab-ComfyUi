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

1. Clone this repo **with submodules**:
   ```bash
   git clone --recurse-submodules https://github.com/<your-username>/GenAI-Lab-ComfyUi.git
   cd GenAI-Lab-ComfyUi
````

2. Run the macOS setup script (it will ask you to name your environment, e.g. `comfyui-env`):

   ```bash
   ./setup_conda_mac.sh
   ```

3. Activate the environment and launch ComfyUI:

   ```bash
   conda activate comfyui-env
   export PYTORCH_ENABLE_MPS_FALLBACK=1
   python comfyui/main.py
   ```

4. Open the local endpoint:

   ```bash
   Starting server
   To see the GUI go to: http://127.0.0.1:8188
   ```

---

### Steps (Linux + NVIDIA GPU, e.g. 4060 Ti)

1. Clone the repo and init submodules:

   ```bash
   git clone --recurse-submodules https://github.com/<your-username>/GenAI-Lab-ComfyUi.git
   cd GenAI-Lab-ComfyUi
   ```

2. Run the Linux setup script (it will install CUDA-enabled PyTorch if an NVIDIA GPU is detected):

   ```bash
   ./setup_conda_linux.sh comfyui-env
   ```

3. Activate and run ComfyUI with GPU:

   ```bash
   conda activate comfyui-env
   cd comfyui
   python main.py --gpu-only --normalvram
   ```

   > 💡 If you have an 8GB card (4060 / 4060 Ti), and you hit **out-of-memory (OOM)**, try:
   >
   > ```bash
   > python main.py --lowvram --async-offload
   > ```

---

## Workflows

This repo includes a set of curated ComfyUI workflows to show a progression
from beginner to advanced use cases.

| # | Workflow                  | Description                          | Skills Demonstrated              |
| - | ------------------------- | ------------------------------------ | -------------------------------- |
| 1 | Simple I2V (14/25 frames) | Basic still → short motion           | Verify install, environment mgmt |
| 2 | LTXVideo Anime Clip       | Slam Dunk panel → 5–7s video         | Custom node install, anime-style |
| 3 | HunyuanVideo I2V          | Richer motion from still             | Large model integration          |
| 4 | Nvidia Cosmos Interp      | Transition between two images        | Multi-input workflows            |
| 5 | Custom Hybrid SlamDunk    | Your design: motion + LoRA + upscale | Pipeline design, creativity      |

Each workflow JSON is saved in `workflows/`, with sample inputs and outputs in `examples/`.

---

### 1. Simple I2V (14/25 frames)

0. Download models using `download_models.sh`

   ```bash
   caffeinate -dimsu tmux new -d -s downloads './workflows/1_simple_i2v/download_models.sh'
   ```

   Reattach

   ```bash
   tmux attach -t downloads
   ```

   Detach:

   ```bash
   Control + b -> d
   ```

   Kill

   ```bash
   tmux kill-session -t downloads
   ```

1. Using existing template, adjust the model per your setup.

2. Run the workflow in ComfyUI, experiment with prompts, and inspect performance on **M3 vs 4060 Ti**.

---

