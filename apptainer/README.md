# Apptainer Scripts

Scripts for building and running experiments inside a [Apptainer](https://apptainer.org/) container with CUDA support. The container is intended for running on HPC systems with a SLURM scheduler.

## What is in this directory

```text
apptainer/
├── mycontainer.def              # Container definition (CUDA 12.8.1 + Ubuntu 24.04)
├── 01_build-apptainer.sh      # Build the container image
├── 02_run-apptainer-shell.sh  # Open an interactive shell in the container
├── 03_install-vllm.sh           # Install Python dependencies inside the container
├── run-script.sh                # Entry point executed inside the container
├── run-apptainer-script.sh    # Wrapper that launches the container and runs the entry point
└── submit-devana.slurm          # Example SLURM job file
```

## Assumptions

The scripts expect you to run them from the root of your repository, not from inside the `apptainer/` folder. That root directory is bind-mounted into the container and is where all your code is expected to live.

The scripts also expect a writable home area for the container image and environment. By default this is `~/apphome`, but you can override it with `APPHOME`.

## Build the image

Load the apptainer module on your cluster (if required), then build the image from the repository root:

```bash
module load apptainer  # if required on your cluster
bash apptainer/01_build-apptainer.sh
```

This creates `~/apphome/cuda.sif` unless you override `APPHOME`.

> **Note:** If you do not have privilege to run `apptainer build` on the HPC cluster, you can build the container image on your local computer (where you have Singularity/Apptainer installed) and then copy the `.sif` file to `~/apphome` on the HPC system.

## Install Python dependencies

Open a shell inside the container and run the install script once:

```bash
bash apptainer/02_run-apptainer-shell.sh
# inside the container
bash apptainer/03_install-vllm.sh
```

The install script creates a virtual environment at `$VIRTUAL_ENV` inside `APPHOME` and installs all dependencies from the project's `pyproject.toml` or `uv.lock` using `uv sync`.

After installation, authenticate to Hugging Face if needed:

```bash
hf auth login
```

## Open an interactive shell

```bash
bash apptainer/02_run-apptainer-shell.sh
```

This starts an interactive shell with GPU access, mounts the current repository into the container, and exposes the container venv on `PATH`.

## Run an experiment

Run the the experiments on the login node:

```bash
bash apptainer/run-apptainer-script.sh ...
```

## SLURM example

`submit-devana.slurm` is a template for running on a SLURM GPU node. Fill in the account and job name, then submit it with:

```bash
sbatch apptainer/submit-devana.slurm
```

Inside that job, use `srun` or a direct shell invocation to call `apptainer/run-apptainer-script.sh`.

## Notes

* `APPHOME` lets you place the image and venv on shared scratch instead of your home directory.
* The scripts assume the cluster provides the `apptainer` module. If your site uses `singularity` instead, adjust the module and command names accordingly.
* If you change the container definition, rebuild the image before reinstalling dependencies.