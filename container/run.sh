#!/bin/bash
set -euo pipefail
# Runs evaluation in the apptainer environment.
# Called directly or from a SLURM script.
# Usage: run-apptainer-eval.sh <model-name>
#
# Run from the main script directory, not from the apptainer directory.
# Requires a prepared ~/apphome directory with an apptainer image
# and an installed Python virtual environment.

ALL_ARGS="$*"
echo "All arguments: $ALL_ARGS"

CHOME="${APPHOME:-$HOME/apphome}"
echo "Using CHOME=$CHOME"

CURRENT_DIR=$(basename "$(pwd)")
echo "Current directory: $CURRENT_DIR"

# load apptainer module if it is not available by default
# module load apptainer

"$CONTAINER_CMD" exec --nv \
    --home "$CHOME" \
    --bind "$(pwd):/home/$CURRENT_DIR" \
    --pwd /home/$CURRENT_DIR \
    --env VIRTUAL_ENV="$CHOME/venv" \
    --env PATH="$CHOME/.local/bin:$CHOME/venv/bin:$PATH" \
    "$CHOME/cuda.sif" \
    bash container/run-script.sh $ALL_ARGS
