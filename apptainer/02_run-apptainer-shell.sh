#!/bin/bash
set -euo pipefail
# Opens an interactive shell in the apptainer environment.
#
# Run from the main script directory, not from the apptainer directory.
# Requires a prepared ~/apphome directory with an apptainer image
# and an installed Python virtual environment.

CHOME="${APPHOME:-$HOME/apphome}"
echo "Using CHOME=$CHOME"

CURRENT_DIR=$(basename "$(pwd)")
echo "Current directory: $CURRENT_DIR"

# load apptainer module if it is not available by default
# module load apptainer

apptainer shell --nv \
    --home "$CHOME" \
    --bind "$(pwd):/home/$CURRENT_DIR" \
    --pwd /home/$CURRENT_DIR \
    --env VIRTUAL_ENV="$CHOME/venv" \
    --env PATH="$CHOME/.local/bin:$CHOME/venv/bin:$PATH" \
    "$CHOME/cuda.sif"
