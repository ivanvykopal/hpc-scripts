#!/bin/bash
set -euo pipefail
# Runs evaluation in the singularity environment.
# Called directly or from a SLURM script.
# Usage: run-singularity-script.sh [args...]
#
# Run from the main script directory, not from the singularity directory.
# Requires a prepared ~/apphome directory with a singularity image
# and an installed Python virtual environment.

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [args...]" >&2
    exit 1
fi

CHOME="${APPHOME:-$HOME/apphome}"
echo "Using CHOME=$CHOME"

CURRENT_DIR=$(basename "$(pwd)")
echo "Current directory: $CURRENT_DIR"

# load singularity module if it is not available by default
# module load singularity

singularity exec --nv \
    --home "$CHOME" \
    --bind "$(pwd):/home/$CURRENT_DIR" \
    --pwd /home/$CURRENT_DIR \
    --env VIRTUAL_ENV="$CHOME/venv" \
    --env PATH="$CHOME/.local/bin:$CHOME/venv/bin:$PATH" \
    "$CHOME/cuda.sif" \
    bash singularity/run-script.sh "$@"
