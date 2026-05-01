#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
# Prepares a directory with the container image.
# The directory later serves as the container home directory.
mkdir -p ~/apphome
cd ~/apphome
echo "$SCRIPT_DIR"

# Load the singularity module and build the container image using the definition file.
# module load singularity

singularity build --fakeroot cuda.sif "$SCRIPT_DIR/mycontainer.def"
