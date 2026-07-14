# Container Scripts

Scripts for building and running an evaluation environment inside a container with CUDA support. Works with both [Apptainer](https://apptainer.org/) and [Singularity](https://docs.sylabs.io/guides/latest/user-guide/) — the runtime is auto-detected. The container is used to run GPU evaluations in isolated, reproducible environments, including on SLURM HPC clusters.

## Directory Overview

```
container/
├── container-env.sh      # Shared runtime detection (sourced by other scripts)
├── mycontainer.def        # Container definition (CUDA 12.8.1 + Ubuntu 24.04)
├── build.sh              # Build the container image
├── shell.sh              # Open an interactive shell inside the container
├── install-vllm.sh       # Install Python dependencies inside the container
├── run.sh                # Run an evaluation inside the container
└── run-script.sh         # Evaluation entry point (called inside the container)
```

## Container Runtime

All scripts source [`container-env.sh`](container-env.sh), which auto-detects the container runtime:

1. If `CONTAINER_CMD` is already set in the environment, use it as-is.
2. Try `apptainer` (preferred).
3. Fall back to `singularity`, attempting `module load singularity` on HPC clusters.

To force a specific runtime:
```bash
CONTAINER_CMD=singularity bash container/run.sh Qwen/Qwen3-0.6B
```

## Setup

### 1. Build the container image

Run from the repository root:

```bash
bash container/build.sh
```

This creates `~/apphome/cuda.sif` from [`mycontainer.def`](mycontainer.def) (CUDA 12.8.1 + cuDNN on Ubuntu 24.04) using `--fakeroot`.

### 2. Install dependencies inside the container

Open a shell in the container and run the install script:

```bash
bash container/shell.sh
# Inside the container:
bash container/install-vllm.sh
```

This installs into the container's virtual environment (`$VIRTUAL_ENV`, set to `~/apphome/venv`):
- [uv](https://github.com/astral-sh/uv) package manager
- The project dependencies (via `uv sync`)

After installation, authenticate inside the container:
```bash
hf auth login
```

## Running Evaluations

Run from the repository root:

```bash
bash container/run.sh <model-name> [additional-args]

# Example:
bash container/run.sh Qwen/Qwen3-0.6B
```

`run.sh` starts a container `exec` with GPU access (`--nv`), binds the current directory into the container at `/home/<directory-name>`, and runs the in-container entry point [`run-script.sh`](run-script.sh) with the model name as the first argument. `run.sh` can also be invoked from a SLURM submission script.

> **Note:** `run-script.sh` is a skeleton. It sets up the uv environment (`uv use python3.11.5` + `uv sync`) and expects you to fill in the actual evaluation command (e.g. `uv run python ... "$@"`). The commented-out lines show both the `uv run` and active-venv options.

## Interactive Shells

```bash
# Open an interactive shell in the container (local machine):
bash container/shell.sh
```

The container shell has GPU access (`--nv`) and the virtual environment on `PATH`. Must be run from the **repository root**.

## Configuration

The container home directory defaults to `~/apphome`. Override it by setting the `APPHOME` environment variable (affects `shell.sh` and `run.sh`):

```bash
APPHOME=/scratch/myuser/apphome bash container/run.sh Qwen/Qwen3-0.6B
```

## Script Reference

### [`build.sh`](build.sh)
Builds the container image from [`mycontainer.def`](mycontainer.def) into `~/apphome/cuda.sif` using `--fakeroot`. Sources [`container-env.sh`](container-env.sh) for runtime detection.

### [`shell.sh`](shell.sh)
Opens an interactive container shell with GPU access and the virtual environment on `PATH`. Sets `VIRTUAL_ENV=~/apphome/venv` and binds the current directory to `/home/<directory-name>`. Must be run from the **repository root**.

### [`install-vllm.sh`](install-vllm.sh)
Installs Python dependencies into the container's virtual environment (`$VIRTUAL_ENV`). Must be run **inside** the container (e.g., via `shell.sh`). Installs uv, then runs `uv use python3.11.5` and `uv sync` to install the project dependencies. Requires `VIRTUAL_ENV` to be set (done automatically by `shell.sh`).

### [`run.sh`](run.sh)
Runs evaluation inside the container with GPU access. Usage:
```bash
bash container/run.sh <model-name> [additional-args]
```
Must be run from the **repository root**. Binds the repository to `/home/<directory-name>` inside the container and invokes `run-script.sh` with the model name as the first argument. Can be called directly or from a SLURM script.

### [`run-script.sh`](run-script.sh)
Entry point executed **inside** the container by `run.sh`. Prepares the uv environment (`uv use python3.11.5` + `uv sync`) and is intended to run the evaluation with the model name as the first argument and remaining arguments forwarded to the Python evaluation runner. Not called directly — invoked by `run.sh`.
