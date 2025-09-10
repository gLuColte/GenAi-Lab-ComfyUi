
# GenAI-Lab-ComfyUi

This project is a lightweight testbed for running **[ComfyUI](https://github.com/comfyanonymous/ComfyUI)** on Apple Silicon (M3).
The goal is to spin up ComfyUI completely from scratch, install dependencies in an isolated conda environment, and try a few example workflows to explore how well it runs on an M3 Mac using **PyTorch MPS acceleration**.

## Installation

### Requirements
- macOS (Apple Silicon M3 recommended)  
- [conda](https://docs.conda.io/en/latest/) or [miniconda](https://docs.conda.io/en/latest/miniconda.html)  
- Git  

### Steps
1. Clone this repo **with submodules**:
   ```bash
   git clone --recurse-submodules https://github.com/<your-username>/GenAI-Lab-ComfyUi.git
   cd GenAI-Lab-ComfyUi
    ```

2. Run the setup script (it will ask you to name your environment, e.g. `comfyui-env`):

   ```bash
   ./setup_conda.sh
   ```

   Or pass the env name directly:

   ```bash
   ./setup_conda.sh comfyui-env
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

## Workflows

This repo includes a set of curated ComfyUI workflows to show a progression
from beginner to advanced use cases on Apple Silicon (M3).

| # | Workflow | Description | Skills Demonstrated |
|---|----------|-------------|---------------------|
| 1 | Simple I2V (14/25 frames) | Basic still → short motion | Verify install, environment mgmt |
| 2 | LTXVideo Anime Clip | Slam Dunk panel → 5–7s video | Custom node install, anime-style |
| 3 | HunyuanVideo I2V | Richer motion from still | Large model integration |
| 4 | Nvidia Cosmos Interp | Transition between two images | Multi-input workflows |
| 5 | Custom Hybrid SlamDunk | Your design: motion + LoRA + upscale | Pipeline design, creativity |

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
